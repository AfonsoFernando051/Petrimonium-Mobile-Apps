import 'package:flutter/foundation.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_wallet/core/events/app_event.dart';
import 'package:petrimonium_wallet/core/events/app_event_bus.dart';
import 'package:petrimonium_wallet/core/utils/friendly_error_message.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/gamification_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/domain/entities/wealth_change_breakdown.dart';
import 'package:petrimonium_wallet/features/portfolio/domain/services/monthly_wealth_series.dart';

/// Owns all state for the redesigned Portfolio screen: real holdings/
/// summary/allocation/history from the backend, plus everything derived
/// client-side from that real data (health score, insights, estimated
/// passive income). Achievement unlocks, missions and XP/level are a
/// separate concern owned by [GamificationController] — when one is
/// supplied, every successful [loadAll] also re-evaluates it with the
/// portfolio's current net worth, the same "optional injected collaborator"
/// shape this class already used for `MascotController` before the two
/// concerns were split. Keeping the call inside [loadAll] (rather than
/// requiring every caller to separately drive gamification) means every
/// existing entry point that reloads the portfolio — the dashboard's
/// initial load, adding an asset, editing/deleting a lot, pulling to
/// refresh Proventos — keeps re-evaluating gamification exactly as before
/// the split, with no changes needed at those call sites.
class PortfolioController extends ChangeNotifier with SafeChangeNotifier {
  PortfolioController({
    required PortfolioRepository repository,
    GamificationController? gamificationController,
    AppEventBus? eventBus,
  }) : _repository = repository,
       _gamificationController = gamificationController,
       _eventBus = eventBus ?? AppEventBus.instance;

  final PortfolioRepository _repository;
  final GamificationController? _gamificationController;
  final AppEventBus _eventBus;

  /// Whether a `loadAll()` has ever completed successfully this session —
  /// gates [FirstInvestmentAddedEvent] so a cold-start load of an
  /// already-invested user's real holdings is never mistaken for a fresh
  /// purchase (see `loadAll`).
  bool _hasLoadedOnce = false;

  /// Whether the most recently loaded portfolio was above
  /// `_evaluateConcentration`'s high-concentration threshold — tracked so
  /// [HighConcentrationDetectedEvent] only fires on the low→high crossing,
  /// not on every subsequent load while it stays high.
  bool _wasHighlyConcentrated = false;

  bool isLoading = true;
  String? error;

  /// When [holdings]/[summary]/[allocation] were last fetched from the
  /// backend — the real data-provenance timestamp for the "DADO" chip on
  /// Home/`FirstValueScreen`. Deliberately captured here rather than read as
  /// `DateTime.now()` at render time: a render-time clock advances on every
  /// rebuild (a scroll, a theme change) with no new network call behind it,
  /// which is indistinguishable on screen from an actual refresh (DEM-97).
  DateTime? lastRefreshedAt;

  /// Whether any current holding's price isn't a live quote (stale
  /// purchase-price fallback or an unquoted asset class) — the chip must
  /// say so instead of implying full freshness (DEM-97 point 3; mirrors the
  /// per-holding badge in `asset_row.dart`).
  bool get hasStaleQuote => holdings.any((h) => !h.hasLiveQuote);

  List<Holding> holdings = [];
  PortfolioSummary summary = PortfolioSummary.empty;
  List<AllocationSlice> allocation = [];

  HistoryRange selectedRange = HistoryRange.m3;
  InvestmentTypeEnum? selectedAssetFilter;
  List<HistoryPoint> chartPoints = [];

  double todayChangeValue = 0;
  double todayChangePercent = 0;
  double monthlyChangeValue = 0;
  double monthlyChangePercent = 0;
  double annualChangeValue = 0;
  double annualChangePercent = 0;

  final Map<HistoryRange, List<HistoryPoint>> _backendHistoryCache = {};

  // Real, provider-confirmed dividend/JCP/yield history for the user's real
  // holdings (contrast with `passiveIncome` below, which is an *estimate*).
  // Loaded lazily — only the Proventos tab needs it, and each ticker is a
  // real external API round-trip server-side, so Home/Carteira shouldn't pay
  // for it on every load.
  bool isDividendRadarLoading = false;
  String? dividendRadarError;
  DividendRadar dividendRadar = DividendRadar.empty;
  bool _dividendRadarLoaded = false;

  /// Whether the real dividend radar has actually been fetched this session.
  /// The dashboard's Proventos/Lucro KPIs must tell "we haven't fetched it
  /// yet" apart from "you really received R$ 0" — [DividendRadar.empty] is
  /// indistinguishable from a genuinely empty radar on its own, and showing
  /// a placeholder zero as if it were real is exactly the fabrication the
  /// three-layer guardrail exists to prevent.
  bool get isDividendRadarLoaded => _dividendRadarLoaded;

  /// Real proventos (dividendos/JCP/rendimentos) actually received over the
  /// trailing 12 months — `null` until the radar has been fetched, so the
  /// dashboard can show "--" rather than a fabricated zero.
  double? get proventos12m => _dividendRadarLoaded ? dividendRadar.receivedInLast12Months() : null;

  /// Total profit = realised proventos + unrealised capital gain. `null`
  /// while [proventos12m] is still unknown, for the same reason.
  double? get totalProfit {
    final proventos = proventos12m;
    if (proventos == null) return null;
    return summary.totalGain + proventos;
  }

  /// The trailing-12-month series behind the dashboard's "Evolução do
  /// patrimônio" bars, one sample per calendar month. Empty until the 1Y
  /// history has been fetched (see [_loadPerformanceDeltas]).
  List<MonthlyWealthPoint> get monthlyWealth12m =>
      MonthlyWealthSeries.fromHistory(_backendHistoryCache[HistoryRange.y1] ?? const []);

  PortfolioStats get stats => PortfolioStats(summary: summary, holdings: holdings, allocation: allocation);

  PortfolioHealth get health => PortfolioHealthCalculator.calculate(stats);

  /// Whether the wallet currently holds any asset type that pays out
  /// dividends/proventos (ações, FIIs, ETFs/fundos) — the Proventos tab is
  /// only worth showing when this is true.
  bool get hasDividendPayingHoldings => holdings.any((h) => h.type.paysDividends);

  PassiveIncomeEstimate get passiveIncome => PassiveIncomeEstimator.estimate(stats);

  List<InvestmentLot> get _allLots => holdings.expand((h) => h.lots).toList();

  /// Home's "o que mudou (últimos 30 dias)" breakdown — real, derived from
  /// the same lot data behind the Wealth Evolution chart plus the real
  /// `DividendRadar` history (call [loadDividendRadarIfNeeded] so the
  /// rendimentos figure isn't stuck at 0 while it's still unfetched). `null`
  /// with no holdings, or with fewer than two real history samples to diff
  /// (nothing to report yet) — shown as an honest empty state, never a
  /// fabricated zero.
  WealthChangeBreakdown? get wealthChange30d {
    final lots = _allLots;
    if (lots.isEmpty) return null;

    final points = WealthHistoryCalculator.compute(lots, HistoryRange.d30);
    if (points.length < 2) return null;

    final first = points.first;
    final last = points.last;
    final totalChange = last.portfolioValue - first.portfolioValue;
    final aportes = last.investedCapital - first.investedCapital;

    return WealthChangeBreakdown(
      valorizacao: totalChange - aportes,
      aportes: aportes,
      rendimentos: dividendRadar.receivedInLastDays(30),
    );
  }

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifySafely();

    try {
      final results = await Future.wait([
        _repository.fetchHoldings(),
        _repository.fetchAllocation(),
        _repository.fetchSummary(),
      ]);
      // Captured before overwriting `holdings` below, and gated on
      // `_hasLoadedOnce` so this session's very first successful load (which
      // may simply be reading an already-invested user's real portfolio)
      // never reads as "just went from 0 to N holdings".
      final hadNoHoldingsBefore = _hasLoadedOnce && holdings.isEmpty;
      holdings = results[0] as List<Holding>;
      allocation = results[1] as List<AllocationSlice>;
      summary = results[2] as PortfolioSummary;
      _hasLoadedOnce = true;
      lastRefreshedAt = DateTime.now();

      await _loadPerformanceDeltas();
      _recomputeChart();
      await _gamificationController?.evaluate(currentNetWorth: summary.currentValue);

      if (hadNoHoldingsBefore && holdings.isNotEmpty) {
        _eventBus.emit(const FirstInvestmentAddedEvent());
      }
      _evaluateConcentration();
    } catch (e) {
      error = friendlyErrorMessage(e);
    }

    isLoading = false;
    notifySafely();
  }

  Future<void> refresh() => loadAll();

  /// Fetches the real dividend radar on first use and caches it for the rest
  /// of the session; call again via [refreshDividendRadar] to force a reload
  /// (e.g. pull-to-refresh on the Proventos tab).
  Future<void> loadDividendRadarIfNeeded() async {
    if (_dividendRadarLoaded || isDividendRadarLoading) return;
    await _fetchDividendRadar();
  }

  Future<void> refreshDividendRadar() => _fetchDividendRadar();

  Future<void> _fetchDividendRadar() async {
    isDividendRadarLoading = true;
    dividendRadarError = null;
    notifySafely();

    try {
      dividendRadar = await _repository.fetchDividendRadar();
      _dividendRadarLoaded = true;
    } catch (e) {
      dividendRadarError = friendlyErrorMessage(e);
    }

    isDividendRadarLoading = false;
    notifySafely();
  }

  void setRange(HistoryRange range) {
    if (range == selectedRange) return;
    selectedRange = range;
    _recomputeChart();
    notifySafely();
  }

  void setAssetFilter(InvestmentTypeEnum? type) {
    if (type == selectedAssetFilter) return;
    selectedAssetFilter = type;
    _recomputeChart();
    notifySafely();
  }

  Future<void> _loadPerformanceDeltas() async {
    if (holdings.isEmpty) {
      todayChangeValue = 0;
      todayChangePercent = 0;
      monthlyChangeValue = 0;
      monthlyChangePercent = 0;
      annualChangeValue = 0;
      annualChangePercent = 0;
      return;
    }

    final thirtyDay = await _cachedBackendHistory(HistoryRange.d30);
    final oneYear = await _cachedBackendHistory(HistoryRange.y1);

    final today = _delta(thirtyDay, fromEnd: true);
    todayChangeValue = today.$1;
    todayChangePercent = today.$2;

    final monthly = _delta(thirtyDay, fromEnd: false);
    monthlyChangeValue = monthly.$1;
    monthlyChangePercent = monthly.$2;

    final annual = _delta(oneYear, fromEnd: false);
    annualChangeValue = annual.$1;
    annualChangePercent = annual.$2;
  }

  /// [fromEnd] compares the last two samples (≈ "today"); otherwise compares
  /// the first and last sample of the series (≈ full-range change).
  (double, double) _delta(List<HistoryPoint> series, {required bool fromEnd}) {
    if (series.length < 2) return (0, 0);
    final from = fromEnd ? series[series.length - 2] : series.first;
    final to = series.last;
    final value = to.portfolioValue - from.portfolioValue;
    final percent = from.portfolioValue == 0 ? 0.0 : (value / from.portfolioValue) * 100;
    return (value, percent);
  }

  Future<List<HistoryPoint>> _cachedBackendHistory(HistoryRange range) async {
    final cached = _backendHistoryCache[range];
    if (cached != null) return cached;
    final points = await _repository.fetchHistory(range);
    _backendHistoryCache[range] = points;
    return points;
  }

  void _recomputeChart() {
    if (selectedAssetFilter != null) {
      final filteredLots = _allLots.where((l) => l.type == selectedAssetFilter).toList();
      chartPoints = WealthHistoryCalculator.compute(filteredLots, selectedRange);
      return;
    }

    final cached = _backendHistoryCache[selectedRange];
    if (cached != null) {
      chartPoints = cached;
      return;
    }

    // Not yet fetched from the backend for this range — compute locally from
    // already-loaded lots so the UI responds instantly, then fetch+replace.
    chartPoints = WealthHistoryCalculator.compute(_allLots, selectedRange);
    _repository
        .fetchHistory(selectedRange)
        .then((points) {
          _backendHistoryCache[selectedRange] = points;
          if (selectedAssetFilter == null) {
            chartPoints = points;
            notifySafely();
          }
        })
        .catchError((_) {
          // Keep the locally-computed series if the backend call fails.
        });
  }

  /// Mirrors `InsightGenerator`'s existing "Concentração elevada" rule
  /// (>40% of the portfolio in one holding) so the pet's alert and the
  /// Insights card agree on what counts as concentrated. Only emits on the
  /// low→high transition — see [_wasHighlyConcentrated].
  void _evaluateConcentration() {
    final isConcentrated = stats.largestHoldingPercent > 40;
    if (isConcentrated && !_wasHighlyConcentrated) {
      final biggest = holdings.first;
      _eventBus.emit(HighConcentrationDetectedEvent(ticker: biggest.ticker, percent: biggest.portfolioPercent));
    }
    _wasHighlyConcentrated = isConcentrated;
  }
}
