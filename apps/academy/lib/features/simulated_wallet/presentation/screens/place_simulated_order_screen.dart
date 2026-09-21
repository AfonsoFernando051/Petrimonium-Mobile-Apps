import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/asset_quote.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order_side.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/controllers/simulated_wallet_controller.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/models/investment_type_display.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/simulation_disclaimer_banner.dart';

/// Search a ticker, pick its investment type, choose buy/sell, enter a
/// quantity, and confirm a simulated order at the current reference price —
/// the price is always fetched from the backend right before confirming,
/// never entered by the user, so the fill always matches what the server
/// will actually execute at.
///
/// The order date defaults to today (a live order). Picking a past date —
/// like Wallet's purchase date — backdates the order to that day's close, so
/// a student can assemble a portfolio "as if" bought months ago and see its
/// real evolution. The price still isn't the student's to type: the close
/// shown here is only a preview; the server re-resolves it on confirm.
///
/// The investment-type grid mirrors Wallet's real `AddAssetScreen` (any
/// asset class, the student's own explicit choice, pre-filled by the same
/// B3-ticker heuristic) — this is the "montar a carteira como bem
/// entender" freedom: nothing here restricts which type of asset a student
/// can add. The backend's `simulated_portfolio` has no type column at all,
/// so the choice is persisted locally per ticker (see
/// `SimulatedWalletController.setTickerType`), never sent in the order
/// request itself.
class PlaceSimulatedOrderScreen extends StatefulWidget {
  const PlaceSimulatedOrderScreen({super.key, required this.controller});

  final SimulatedWalletController controller;

  @override
  State<PlaceSimulatedOrderScreen> createState() => _PlaceSimulatedOrderScreenState();
}

class _PlaceSimulatedOrderScreenState extends State<PlaceSimulatedOrderScreen> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();
  Timer? _debounce;

  List<AssetQuote> _results = [];
  bool _isSearching = false;
  AssetQuote? _selected;
  InvestmentTypeEnum? _selectedType;
  SimulatedOrderSide _side = SimulatedOrderSide.buy;
  bool _isSubmitting = false;

  DateTime _tradeDate = _dateOnly(DateTime.now());
  AssetQuote? _historicalQuote;
  bool _isLoadingHistoricalQuote = false;

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  bool get _isBackdated => _tradeDate.isBefore(_dateOnly(DateTime.now()));

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    setState(() => _selected = null);
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    final results = await widget.controller.searchQuotes(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  Future<void> _selectAsset(AssetQuote quote) async {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _selected = quote;
      _results = [];
      _searchController.text = quote.symbol;
    });

    unawaited(_refreshHistoricalQuote());

    // Pre-fills the type grid with the student's own past choice for this
    // ticker, or the B3-suffix classifier's best guess — never overriding a
    // choice the student already made earlier in this session.
    if (_selectedType == null) {
      final resolved = await widget.controller.resolveDefaultType(quote.symbol);
      if (!mounted || _selected?.symbol != quote.symbol) return;
      setState(() => _selectedType = resolved);
    }
  }

  Future<void> _selectDate() async {
    final tokens = context.colors;
    final picked = await showDatePicker(
      context: context,
      initialDate: _tradeDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: tokens.primary)),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _tradeDate = _dateOnly(picked));
    await _refreshHistoricalQuote();
  }

  /// Previews the close the server will fill a backdated order at. Cleared
  /// for a live order, where the reference price above already applies.
  Future<void> _refreshHistoricalQuote() async {
    final selected = _selected;
    final date = _tradeDate;
    if (selected == null || !_isBackdated) {
      setState(() {
        _historicalQuote = null;
        _isLoadingHistoricalQuote = false;
      });
      return;
    }

    setState(() {
      _historicalQuote = null;
      _isLoadingHistoricalQuote = true;
    });
    AssetQuote? quote;
    try {
      quote = await widget.controller.fetchQuoteAtDate(selected.symbol, date);
    } catch (_) {
      // Same outcome for the student as "no close that day": the order is
      // blocked below rather than falling back to today's price.
    }
    if (!mounted || _selected?.symbol != selected.symbol || _tradeDate != date) return;
    setState(() {
      _historicalQuote = quote;
      _isLoadingHistoricalQuote = false;
    });
  }

  String get _referencePriceText {
    if (!_isBackdated) {
      final price = _selected!.regularMarketPrice;
      return '${Translator.translate(AppStrings.simulatedOrderReferencePriceLabel)}: '
          "${price == null ? '—' : 'R\$ ${price.toStringAsFixed(2)}'}";
    }
    final label = '${Translator.translate(AppStrings.simulatedOrderHistoricalPriceLabel)} ${_formatDate(_tradeDate)}';
    if (_isLoadingHistoricalQuote) return '$label: …';
    final price = _historicalQuote?.regularMarketPrice;
    if (price == null) return Translator.translate(AppStrings.simulatedOrderNoHistoricalQuote);
    return '$label: R\$ ${price.toStringAsFixed(2)}';
  }

  Future<void> _confirm() async {
    final selected = _selected;
    if (selected == null) {
      GameSnack.show(context, Translator.translate(AppStrings.simulatedOrderSelectAssetFirst), isError: true);
      return;
    }
    final type = _selectedType;
    if (type == null) {
      GameSnack.show(context, Translator.translate(AppStrings.simulatedWalletSelectTypeError), isError: true);
      return;
    }
    if (_isBackdated) {
      if (_isLoadingHistoricalQuote) return;
      if (_historicalQuote?.regularMarketPrice == null) {
        GameSnack.show(context, Translator.translate(AppStrings.simulatedOrderNoHistoricalQuote), isError: true);
        return;
      }
    }
    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.'));
    if (quantity == null || quantity <= 0) {
      GameSnack.show(context, Translator.translate(AppStrings.simulatedOrderQuantityLabel), isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    unawaited(HapticFeedback.mediumImpact());
    await widget.controller.setTickerType(selected.symbol, type);
    final order = await widget.controller.placeOrder(
      ticker: selected.symbol,
      side: _side,
      quantity: quantity,
      tradeDate: _isBackdated ? _tradeDate : null,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (order != null) {
      GameSnack.show(context, Translator.translate(AppStrings.simulatedOrderSuccessMessage), isSuccess: true);
      Navigator.of(context).pop();
    } else if (widget.controller.orderError != null) {
      GameSnack.show(context, widget.controller.orderError!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(Translator.translate(AppStrings.simulatedOrderScreenTitle)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SimulationDisclaimerBanner(),
          const SizedBox(height: AppSpacing.md),
          _SideToggle(selected: _side, onChanged: (side) => setState(() => _side = side)),
          const SizedBox(height: AppSpacing.md),
          _TypeGrid(selected: _selectedType, onSelect: (type) => setState(() => _selectedType = type), tokens: tokens),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _searchController,
            onChanged: _onQueryChanged,
            decoration: InputDecoration(
              hintText: Translator.translate(AppStrings.simulatedOrderSearchHint),
              prefixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
            ),
          ),
          if (_results.isNotEmpty)
            GlassCard(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                children: [
                  for (final quote in _results)
                    ListTile(
                      title: Text(quote.symbol, style: TextStyle(color: tokens.textPrimary)),
                      subtitle: quote.shortName == null ? null : Text(quote.shortName!),
                      trailing: quote.regularMarketPrice == null
                          ? null
                          : Text('R\$ ${quote.regularMarketPrice!.toStringAsFixed(2)}'),
                      onTap: () => _selectAsset(quote),
                    ),
                ],
              ),
            ),
          if (_selected != null) ...[
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selected!.symbol, style: AppTextStyles.titleLarge.copyWith(color: tokens.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_referencePriceText, style: AppTextStyles.body.copyWith(color: tokens.textSecondary)),
                  const SizedBox(height: AppSpacing.md),
                  _DateField(
                    tokens: tokens,
                    label: Translator.translate(AppStrings.simulatedOrderDateLabel),
                    text: _isBackdated
                        ? _formatDate(_tradeDate)
                        : Translator.translate(AppStrings.simulatedOrderDateToday),
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: Translator.translate(AppStrings.simulatedOrderQuantityLabel),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _confirm,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(Translator.translate(AppStrings.simulatedOrderConfirmAction)),
          ),
        ],
      ),
    );
  }
}

class _SideToggle extends StatelessWidget {
  const _SideToggle({required this.selected, required this.onChanged});

  final SimulatedOrderSide selected;
  final ValueChanged<SimulatedOrderSide> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return SegmentedButton<SimulatedOrderSide>(
      segments: [
        ButtonSegment(
          value: SimulatedOrderSide.buy,
          label: Text(Translator.translate(AppStrings.simulatedOrderBuyLabel)),
          icon: const Icon(Icons.arrow_upward),
        ),
        ButtonSegment(
          value: SimulatedOrderSide.sell,
          label: Text(Translator.translate(AppStrings.simulatedOrderSellLabel)),
          icon: const Icon(Icons.arrow_downward),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (set) => onChanged(set.first),
      style: SegmentedButton.styleFrom(selectedForegroundColor: tokens.primary),
    );
  }
}

/// Tap-to-pick date row — ported from Wallet's `AddAssetScreen._DateField`,
/// with a visible [label] since here the date has a sensible default (today)
/// rather than being an empty required field.
class _DateField extends StatelessWidget {
  const _DateField({required this.tokens, required this.label, required this.text, required this.onTap});

  final AppColorTokens tokens;
  final String label;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: tokens.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 18, color: tokens.textSecondary),
                const SizedBox(width: 10),
                Text(text, style: TextStyle(color: tokens.textPrimary, fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The 6-card investment-type grid — ported from Wallet's real
/// `AddAssetScreen._TypeGrid`/`_TypeCard`, unchanged: it only paints shared
/// `context.colors` tokens, never a per-type color, so it needed no
/// adaptation beyond `InvestmentTypeEnum`/`InvestmentTypeDisplay`, both
/// already available here.
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
      childAspectRatio: 1.08,
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? tokens.primaryContainer : tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? tokens.primary : tokens.border, width: selected ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? tokens.primary.withValues(alpha: 0.18) : tokens.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected ? Icons.check_circle : type.icon,
                size: 17,
                color: selected ? tokens.primary : tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
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
