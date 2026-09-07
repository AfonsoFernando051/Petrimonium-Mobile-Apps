import 'package:flutter/material.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/utils/game_snack.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/core/widgets/cosmic_background.dart';
import 'package:petrimonium_wallet/features/onboarding/data/models/wallet_base_currency_enum.dart';
import 'package:petrimonium_wallet/features/onboarding/data/models/wallet_market_enum.dart';
import 'package:petrimonium_wallet/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:petrimonium_wallet/main.dart';

/// Screen 2 of 2 in the Wallet's mini-onboarding: country/market and
/// base-currency, the only setup this app asks for before Home. Both
/// pickers currently resolve to a single option (see [WalletMarketEnum]
/// doc) — real, extensible selectors rather than static text, without
/// pretending multi-market support that doesn't exist yet.
///
/// Also reused, via [isSettingsMode], as Perfil's "Moeda-base e mercado" —
/// same fields/pickers, loaded with the saved values instead of defaults,
/// a plain back-button Scaffold instead of the onboarding step chrome, and
/// "Salvar" (save-and-pop) instead of completing onboarding.
class QuickSetupScreen extends StatefulWidget {
  const QuickSetupScreen({super.key, this.isSettingsMode = false, this.totalSteps = 2});

  final bool isSettingsMode;

  /// 2 for the common case (account already has a Pet) or 3 when
  /// `PetSetupScreen` ran first — this screen is always the last step, so
  /// its own step number is [totalSteps] itself. Unused in settings mode.
  final int totalSteps;

  @override
  State<QuickSetupScreen> createState() => _QuickSetupScreenState();
}

class _QuickSetupScreenState extends State<QuickSetupScreen> {
  WalletMarketEnum _market = WalletMarketEnum.brazilB3;
  late WalletBaseCurrencyEnum _currency = _market.defaultCurrency;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isSettingsMode) _loadSavedValues();
  }

  Future<void> _loadSavedValues() async {
    final market = await DI.walletMarketPreferencesRepository.loadMarket();
    final currency = await DI.walletMarketPreferencesRepository.loadBaseCurrency();
    if (!mounted) return;
    setState(() {
      _market = market;
      _currency = currency;
    });
  }

  void _selectMarket(WalletMarketEnum market) {
    if (market == _market) return;
    setState(() {
      _market = market;
      // Como no artboard: trocar de mercado aplica a moeda sugerida da
      // região; a moeda continua livre para ser sobrescrita a seguir.
      _currency = market.defaultCurrency;
    });
  }

  Future<void> _handleContinue() async {
    setState(() => _isLoading = true);
    await DI.walletMarketPreferencesRepository.saveMarket(_market);
    await DI.walletMarketPreferencesRepository.saveBaseCurrency(_currency);

    if (widget.isSettingsMode) {
      if (mounted) {
        GameSnack.show(context, Translator.translate(AppStrings.quickSetupSavedSnack));
        Navigator.of(context).pop();
      }
      return;
    }

    await DI.onboardingStateRepository.markQuickSetupDone();
    if (mounted) {
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyApp()),
        (route) => false,
      );
    }
  }

  Widget _buildFields(BuildContext context) {
    final tokens = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(Translator.translate(AppStrings.quickSetupMarketLabel)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final market in WalletMarketEnum.values)
              OptionPill(
                leading: market.flag,
                label: market.label,
                selected: market == _market,
                onTap: () => _selectMarket(market),
              ),
          ],
        ),
        const SizedBox(height: 20),
        FieldLabel(Translator.translate(AppStrings.quickSetupCurrencyLabel)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final currency in WalletBaseCurrencyEnum.values)
              OptionPill(
                label: currency.label,
                selected: currency == _currency,
                onTap: () => setState(() => _currency = currency),
              ),
          ],
        ),
        if (!widget.isSettingsMode) ...[
          const SizedBox(height: 20),
          // Caixa com contorno, como no artboard `PrefsWallet` — era texto solto.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.textPrimary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.textPrimary.withValues(alpha: 0.12)),
            ),
            child: Text(
              Translator.translate(AppStrings.quickSetupFooterNote),
              style: TextStyle(color: tokens.textSecondary, fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSettingsMode) return _buildSettingsScaffold(context);

    return OnboardingScaffold(
      step: widget.totalSteps,
      totalSteps: widget.totalSteps,
      title: Translator.translate(AppStrings.quickSetupTitle),
      subtitle: Translator.translate(AppStrings.quickSetupSubtitle),
      ctaLabel: Translator.translate(AppStrings.quickSetupCta),
      isCtaLoading: _isLoading,
      onCta: _handleContinue,
      body: _buildFields(context),
    );
  }

  Widget _buildSettingsScaffold(BuildContext context) {
    final tokens = context.colors;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          Translator.translate(AppStrings.profileCurrencyMarketLabel),
          style: TextStyle(color: tokens.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  Translator.translate(AppStrings.quickSetupSettingsSubtitle),
                  style: TextStyle(color: tokens.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                _buildFields(context),
                const SizedBox(height: 28),
                GameButton(
                  label: Translator.translate(AppStrings.quickSetupSaveCta),
                  isLoading: _isLoading,
                  onPressed: _handleContinue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
