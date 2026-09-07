import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/utils/financial_input_validators.dart';
import 'package:petrimonium/core/utils/formatters.dart';
import 'package:petrimonium/core/utils/friendly_error_message.dart';
import 'package:petrimonium/core/utils/game_snack.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/cosmic_background.dart';
import 'package:petrimonium/core/widgets/game_button.dart';
import 'package:petrimonium/features/investment/data/models/asset_registration_model.dart';
import 'package:petrimonium/features/investment/data/models/investment_type_enum.dart';
import 'package:petrimonium/features/investment/domain/services/ticker_type_classifier.dart';
import 'package:petrimonium/features/portfolio/domain/entities/investment_type_display.dart';
import 'package:petrimonium/features/portfolio/presentation/controllers/portfolio_controller.dart';

/// Wallet's own "add one asset" screen — reached from Home's "Adicionar"
/// action once a portfolio already exists. Deliberately separate from
/// `InvestmentConfigurationScreen`: that screen is the gamified, multi-asset
/// Academy-style onboarding wizard (nebula background, Pet companion,
/// unlockable rewards, "Portfólio Inicial") kept as-is for the zero-holdings
/// first-time setup; this one is the plain, single-asset, "Mentor mais
/// discreto" Wallet screen the design calls for.
///
/// The backend only exposes a whole-portfolio "configure" endpoint (no
/// single-asset append), so submitting here still re-sends every existing
/// holding plus the new one with `confirmReplace: true` — same mechanism as
/// `InvestmentConfigurationScreen`, just hidden behind a one-asset form.
class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key, required this.controller});

  final PortfolioController controller;

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  InvestmentTypeEnum? _selectedType;
  DateTime? _selectedDate;
  bool _isLoading = false;

  /// Every existing holding, expanded back into per-lot registration models
  /// — resubmitted alongside the new asset since `configureInvestments`
  /// replaces the whole portfolio. `null` while still loading.
  List<AssetRegistrationModel>? _existingAssets;
  double _currentTotalValue = 0;
  bool _holdingsLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _quantityController.addListener(_onFieldChanged);
    _priceController.addListener(_onFieldChanged);
    _loadExistingHoldings();
  }

  void _onFieldChanged() => setState(() {});

  Future<void> _loadExistingHoldings() async {
    try {
      final holdings = await DI.portfolioRepository.fetchHoldings();
      final existing = holdings
          .expand((holding) => holding.lots)
          .map((lot) => AssetRegistrationModel(
                name: lot.ticker,
                quantity: lot.quantity,
                purchasePrice: lot.purchasePrice,
                purchaseDate: _formatDate(lot.purchaseDate),
                type: lot.type,
              ))
          .toList();
      if (!mounted) return;
      setState(() {
        _existingAssets = existing;
        _currentTotalValue = holdings.fold<double>(0, (sum, h) => sum + h.currentValue);
        _holdingsLoadFailed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _holdingsLoadFailed = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  double get _estimatedValue {
    final quantity = FinancialInputValidators.parsePositiveDecimal(_quantityController.text) ?? 0;
    final price = FinancialInputValidators.parsePositiveDecimal(_priceController.text) ?? 0;
    return quantity * price;
  }

  bool get _canSubmit =>
      !_isLoading &&
      !_holdingsLoadFailed &&
      _existingAssets != null &&
      _nameController.text.trim().isNotEmpty &&
      FinancialInputValidators.parsePositiveDecimal(_quantityController.text) != null &&
      FinancialInputValidators.parsePositiveDecimal(_priceController.text) != null &&
      _selectedType != null &&
      _selectedDate != null;

  String? _tickerTypeMismatch(String? tickerText) {
    if (_selectedType == null || tickerText == null || tickerText.isEmpty) return null;
    final detected = TickerTypeClassifier.classify(tickerText);
    if (detected == null || detected == _selectedType) return null;
    return 'Esse ticker parece ser ${detected.label}, não ${_selectedType!.label}.';
  }

  Future<void> _selectDate() async {
    final tokens = context.colors;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: tokens.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    await _refreshPriceForSelectedDate();
  }

  /// Re-fetches the ticker's historical price so editing the purchase date
  /// keeps the price field truthful to that date — same behavior as
  /// `InvestmentConfigurationScreen`.
  Future<void> _refreshPriceForSelectedDate() async {
    final ticker = _nameController.text.trim();
    if (ticker.isEmpty || _selectedDate == null) return;

    final quote = await DI.investmentRepository.fetchQuoteAtDate(ticker, _formatDate(_selectedDate!));
    final price = quote?['regularMarketPrice'];
    if (price != null && mounted) {
      setState(() => _priceController.text = price.toString());
    }
  }

  Future<void> _handleAdd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      GameSnack.show(context, Translator.translate(AppStrings.addAssetSelectTypeError), isError: true);
      return;
    }
    if (_selectedDate == null) {
      GameSnack.show(context, Translator.translate(AppStrings.addAssetSelectDateError), isError: true);
      return;
    }

    final quantity = FinancialInputValidators.parsePositiveDecimal(_quantityController.text);
    final price = FinancialInputValidators.parsePositiveDecimal(_priceController.text);
    final existing = _existingAssets;
    if (quantity == null || price == null || existing == null) return;

    final newAsset = AssetRegistrationModel(
      name: _nameController.text.trim(),
      quantity: quantity,
      purchasePrice: price,
      purchaseDate: _formatDate(_selectedDate!),
      type: _selectedType!,
    );

    setState(() => _isLoading = true);
    try {
      await DI.investmentRepository.configureInvestments([...existing, newAsset], confirmReplace: true);
      await widget.controller.refresh();
      if (mounted) {
        GameSnack.showWithHaptic(context, Translator.translate(AppStrings.addAssetSuccessSnack), isSuccess: true);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        GameSnack.show(
          context,
          '${Translator.translate(AppStrings.addAssetFailedSnack)} ${friendlyErrorMessage(e)}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAutocompleteField(AppColorTokens tokens) {
    return Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.length < 2) return const Iterable<Map<String, dynamic>>.empty();
        final results = await DI.investmentRepository.searchQuotes(textEditingValue.text);
        if (_selectedType == null) return results;
        return results.where((option) {
          final symbol = (option['symbol'] ?? option['stock'] ?? '').toString();
          final detected = TickerTypeClassifier.classify(symbol);
          return detected == null || detected == _selectedType;
        });
      },
      displayStringForOption: (option) => option['symbol']?.toString() ?? option['stock']?.toString() ?? '',
      onSelected: (selection) {
        final symbol = selection['symbol']?.toString() ?? selection['stock']?.toString() ?? '';
        setState(() {
          _nameController.text = symbol;
          _priceController.text = selection['regularMarketPrice']?.toString() ?? selection['close']?.toString() ?? '';
          _selectedType ??= TickerTypeClassifier.classify(symbol);
          _formKey.currentState?.validate();
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        controller.addListener(() => _nameController.text = controller.text);
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          style: TextStyle(color: tokens.textPrimary),
          decoration: _fieldDecoration(tokens, hint: Translator.translate(AppStrings.addAssetTickerHint)),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Campo obrigatório';
            return _tickerTypeMismatch(value);
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            elevation: 4,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 320),
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.border),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  final symbol = (option['symbol'] ?? option['stock'] ?? '').toString();
                  final name = (option['shortName'] ?? option['name'] ?? '').toString();
                  final priceRaw = option['regularMarketPrice'] ?? option['close'];
                  final price = priceRaw is num ? priceRaw.toDouble() : double.tryParse(priceRaw?.toString() ?? '');
                  return ListTile(
                    onTap: () => onSelected(option),
                    title: Text(symbol.toUpperCase(), style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: name.isEmpty ? null : Text(name, style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
                    trailing: price == null
                        ? null
                        : Text(AppFormatters.currency(price), style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _fieldDecoration(AppColorTokens tokens, {required String hint, Widget? suffixIcon}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: tokens.border),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: tokens.textTertiary, fontSize: 14),
      filled: true,
      fillColor: tokens.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: suffixIcon,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: tokens.primary, width: 1.5)),
      errorBorder: border.copyWith(borderSide: BorderSide(color: tokens.error)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title: Text(
          Translator.translate(AppStrings.addAssetTitle),
          style: TextStyle(color: tokens.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 90, 20, 24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MentorTipCard(tokens: tokens),
                  const SizedBox(height: 20),
                  if (_holdingsLoadFailed) ...[
                    _LoadFailedBanner(tokens: tokens, onRetry: _loadExistingHoldings),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    Translator.translate(AppStrings.addAssetTypeLabel),
                    style: TextStyle(color: tokens.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  _TypeGrid(
                    selected: _selectedType,
                    tokens: tokens,
                    onSelect: (type) => setState(() {
                      _selectedType = type;
                      _formKey.currentState?.validate();
                    }),
                  ),
                  const SizedBox(height: 20),
                  _buildAutocompleteField(tokens),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: tokens.textPrimary),
                          decoration: _fieldDecoration(tokens, hint: Translator.translate(AppStrings.addAssetQuantityHint)),
                          validator: FinancialInputValidators.quantity,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: tokens.textPrimary),
                          decoration: _fieldDecoration(tokens, hint: Translator.translate(AppStrings.addAssetPriceHint)),
                          validator: FinancialInputValidators.price,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DateField(
                    tokens: tokens,
                    date: _selectedDate,
                    hint: Translator.translate(AppStrings.addAssetDateHint),
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 20),
                  _SummaryRow(
                    tokens: tokens,
                    estimatedValue: _estimatedValue,
                    portfolioAfter: _currentTotalValue + _estimatedValue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Translator.translate(AppStrings.addAssetFooterNote),
                    style: TextStyle(color: tokens.textTertiary, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  GameButton(
                    label: Translator.translate(AppStrings.addAssetCta),
                    icon: Icons.add,
                    isLoading: _isLoading,
                    pulse: _canSubmit,
                    onPressed: _canSubmit ? _handleAdd : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MentorTipCard extends StatelessWidget {
  const _MentorTipCard({required this.tokens});

  final AppColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/generated_fox.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.pets, size: 24, color: tokens.mentor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              Translator.translate(AppStrings.addAssetMentorTip),
              style: TextStyle(color: tokens.textSecondary, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadFailedBanner extends StatelessWidget {
  const _LoadFailedBanner({required this.tokens, required this.onRetry});

  final AppColorTokens tokens;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: tokens.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              Translator.translate(AppStrings.addAssetLoadFailedBanner),
              style: TextStyle(color: tokens.textPrimary, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(Translator.translate(AppStrings.retryButtonLabel)),
          ),
        ],
      ),
    );
  }
}

class _TypeGrid extends StatelessWidget {
  const _TypeGrid({required this.selected, required this.onSelect, required this.tokens});

  final InvestmentTypeEnum? selected;
  final ValueChanged<InvestmentTypeEnum> onSelect;
  final AppColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: [
        for (final type in InvestmentTypeEnum.values)
          _TypeCard(type: type, selected: type == selected, tokens: tokens, onTap: () => onSelect(type)),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.type, required this.selected, required this.tokens, required this.onTap});

  final InvestmentTypeEnum type;
  final bool selected;
  final AppColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? tokens.primaryContainer : tokens.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? tokens.primary : tokens.border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.check_circle : type.icon,
              size: 16,
              color: selected ? tokens.primary : tokens.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                type.shortLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? tokens.textPrimary : tokens.textSecondary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.tokens, required this.date, required this.hint, required this.onTap});

  final AppColorTokens tokens;
  final DateTime? date;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date == null
                  ? hint
                  : "${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}",
              style: TextStyle(color: date == null ? tokens.textTertiary : tokens.textPrimary, fontSize: 14),
            ),
            Icon(Icons.calendar_today_outlined, size: 18, color: tokens.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.tokens, required this.estimatedValue, required this.portfolioAfter});

  final AppColorTokens tokens;
  final double estimatedValue;
  final double portfolioAfter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              label: Translator.translate(AppStrings.addAssetEstimatedValueLabel),
              value: AppFormatters.currency(estimatedValue),
              color: tokens.textPrimary,
              tokens: tokens,
            ),
          ),
          Expanded(
            child: _SummaryStat(
              label: Translator.translate(AppStrings.addAssetPortfolioAfterLabel),
              value: AppFormatters.currency(portfolioAfter),
              color: tokens.primary,
              tokens: tokens,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value, required this.color, required this.tokens});

  final String label;
  final String value;
  final Color color;
  final AppColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: tokens.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
