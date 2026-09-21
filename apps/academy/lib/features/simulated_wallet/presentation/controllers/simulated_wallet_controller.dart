import 'package:flutter/foundation.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/core/utils/friendly_error_message.dart';
import 'package:petrimonium_academy/features/simulated_wallet/data/repositories/simulated_ticker_type_store.dart';
import 'package:petrimonium_academy/features/simulated_wallet/data/repositories/simulated_wallet_repository.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/asset_quote.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order_side.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_portfolio_summary.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_position.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_position_quote.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/services/monthly_wealth_series.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/services/simulated_lot_builder.dart';

/// Owns all state for the simulated wallet (Academy's fictitious "Carteira"
/// tab) — entirely separate from `PortfolioController`, which still owns
/// the real-portfolio-flavored gamification orchestration (achievements/
/// missions/XP) until that's untangled in a later pass. This controller
/// never touches `PortfolioRepository`/`InvestmentRepository` or any
/// real_portfolio endpoint.
class SimulatedWalletController extends ChangeNotifier {
  SimulatedWalletController({required SimulatedWalletRepository repository, SimulatedTickerTypeStore? typeStore})
    : _repository = repository,
      _typeStore = typeStore ?? SimulatedTickerTypeStore();

  final SimulatedWalletRepository _repository;
  final SimulatedTickerTypeStore _typeStore;

  bool isLoading = true;
  String? error;
  SimulatedPortfolioSummary portfolio = SimulatedPortfolioSummary.empty;

  /// Each held position paired with its current market price, fetched right
  /// after [portfolio] — this is what makes "how much can I gain or lose"
  /// answerable at all, since the portfolio summary itself carries only cost
  /// basis (see `SimulatedPositionQuote`'s class doc). Stays in lockstep with
  /// [portfolio.positions]: recomputed by every call that reloads it.
  List<SimulatedPositionQuote> positionQuotes = [];

  /// The simulated wallet's every executed order — the source of each
  /// position's approximate purchase date (see `SimulatedLotBuilder`).
  List<SimulatedOrder> orders = [];

  /// One [InvestmentLot] per held ticker (see `SimulatedLotBuilder`'s class
  /// doc for what's exact vs. approximated), recomputed alongside
  /// [portfolio]/[positionQuotes]/[orders]. This is the shape the rest of
  /// the Carteira design — `Holding.fromLots`, `WealthHistoryCalculator`,
  /// allocation — already runs on for Wallet's real portfolio.
  List<InvestmentLot> lots = [];

  /// Holdings aggregated by ticker, same shared model Wallet's real Carteira
  /// uses for its `HoldingsSection`.
  List<Holding> get holdings => Holding.fromLots(lots);

  /// Current value grouped by [InvestmentTypeEnum] — the allocation donut's
  /// data, computed client-side since the simulated backend has no
  /// dedicated allocation endpoint (unlike Wallet's real one).
  List<AllocationSlice> get allocation {
    final byType = <InvestmentTypeEnum, double>{};
    for (final holding in holdings) {
      byType[holding.type] = (byType[holding.type] ?? 0) + holding.currentValue;
    }
    final total = byType.values.fold(0.0, (sum, value) => sum + value);
    final slices = byType.entries
        .map(
          (entry) => AllocationSlice(
            type: entry.key,
            currentValue: entry.value,
            portfolioPercent: total == 0 ? 0 : (entry.value / total) * 100,
          ),
        )
        .toList();
    slices.sort((a, b) => b.currentValue.compareTo(a.currentValue));
    return slices;
  }

  /// Trailing 12 months of the Wealth Evolution chart — a pure client-side
  /// interpolation from each lot's purchase to its current price (see
  /// `WealthHistoryCalculator`'s class doc: this needs no backend history
  /// table, Wallet's own per-asset-type chart filter already works this
  /// way).
  List<MonthlyWealthPoint> get monthlyWealth12m =>
      MonthlyWealthSeries.fromHistory(WealthHistoryCalculator.compute(lots, HistoryRange.y1));

  bool isPlacingOrder = false;
  String? orderError;

  bool isResetting = false;
  String? resetError;

  /// Sum of every holding's invested value — "quanto foi investido", the
  /// denominator for [totalProfitPercent].
  double get totalInvestedValue => holdings.fold(0.0, (sum, h) => sum + h.investedValue);

  /// Sum of every holding's current value.
  double get totalPositionsValue => holdings.fold(0.0, (sum, h) => sum + h.currentValue);

  /// Virtual cash still uninvested, plus every position at its current
  /// (or, failing that, cost) value — the single "patrimônio total" figure.
  double get totalPatrimony => portfolio.virtualBalance + totalPositionsValue;

  /// Unrealized gain/loss across every position with a known price. A
  /// position with no quote contributes zero here (neither a gain nor a
  /// loss), never a fabricated figure.
  double get totalProfit => totalPositionsValue - totalInvestedValue;

  double get totalProfitPercent => totalInvestedValue == 0 ? 0 : (totalProfit / totalInvestedValue) * 100;

  Future<void> loadPortfolio() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      portfolio = await _repository.fetchPortfolio();
      await _refreshDerivedState();
    } catch (e) {
      error = friendlyErrorMessage(e);
    }

    isLoading = false;
    notifyListeners();
  }

  /// Re-fetches every held ticker's quote and the order history, then
  /// rebuilds [lots] from them — everything [holdings]/[allocation]/
  /// [monthlyWealth12m] depend on. Called after every successful mutation of
  /// [portfolio] (initial load, a placed order, a reset).
  Future<void> _refreshDerivedState() async {
    final positions = portfolio.positions;
    final results = await Future.wait([_fetchPositionQuotes(positions), _fetchOrders()]);
    positionQuotes = results[0] as List<SimulatedPositionQuote>;
    orders = results[1] as List<SimulatedOrder>;

    final types = await Future.wait(positions.map((p) => _resolveType(p.ticker)));
    final typeByTicker = {for (var i = 0; i < positions.length; i++) positions[i].ticker: types[i]};

    lots = SimulatedLotBuilder.build(
      portfolio: portfolio,
      quotes: positionQuotes,
      orders: orders,
      typeOf: (ticker) => typeByTicker[ticker] ?? InvestmentTypeEnum.OTHERS,
    );
  }

  /// Fetches every held ticker's current quote in parallel. A single ticker
  /// failing to quote (unknown symbol, request error) never fails the whole
  /// portfolio load — see [SimulatedPositionQuote]'s fallback behavior.
  Future<List<SimulatedPositionQuote>> _fetchPositionQuotes(List<SimulatedPosition> positions) {
    return Future.wait(positions.map(_fetchPositionQuote));
  }

  Future<SimulatedPositionQuote> _fetchPositionQuote(SimulatedPosition position) async {
    try {
      final quote = await _repository.fetchQuote(position.ticker);
      return SimulatedPositionQuote(position: position, currentPrice: quote?.regularMarketPrice);
    } catch (_) {
      return SimulatedPositionQuote(position: position, currentPrice: null);
    }
  }

  /// The order history is only used for each lot's approximate purchase
  /// date — losing it is cosmetic (falls back to the reset date, see
  /// `SimulatedLotBuilder`), never fatal to the portfolio load.
  Future<List<SimulatedOrder>> _fetchOrders() async {
    try {
      return await _repository.fetchOrders();
    } catch (_) {
      return const [];
    }
  }

  /// A ticker's investment type for display: the student's own past choice
  /// first, then the B3-suffix classifier, defaulting to [InvestmentTypeEnum
  /// .OTHERS] only as a last resort (a [Holding]/[InvestmentLot] can't be
  /// typeless). Contrast with [resolveDefaultType], which leaves this `null`
  /// so the order screen's type grid asks rather than silently guessing.
  Future<InvestmentTypeEnum> _resolveType(String ticker) async {
    return await resolveDefaultType(ticker) ?? InvestmentTypeEnum.OTHERS;
  }

  /// The type to pre-select on the order screen's type grid for [ticker]:
  /// the student's own stored choice if there is one, else the B3-suffix
  /// classifier's best guess, else `null` (ambiguous — the student must
  /// pick). Never silently overrides an explicit stored choice.
  Future<InvestmentTypeEnum?> resolveDefaultType(String ticker) async {
    final stored = await _typeStore.getStoredType(ticker);
    return stored ?? TickerTypeClassifier.classify(ticker);
  }

  /// Persists the student's chosen type for [ticker] — called by the order
  /// screen right before [placeOrder]. Keyed by ticker only (see
  /// `SimulatedTickerTypeStore`'s class doc: a wallet reset never forgets
  /// what kind of asset a ticker is).
  Future<void> setTickerType(String ticker, InvestmentTypeEnum type) => _typeStore.setType(ticker, type);

  Future<void> refresh() => loadPortfolio();

  /// Places a simulated order and reloads the portfolio on success so the
  /// new balance/position is immediately reflected. A past [tradeDate]
  /// backdates the order to that day's close (the server resolves the
  /// price — see [fetchQuoteAtDate] for the preview); `null` is a live
  /// order. Returns the created order, or `null` if the placement failed
  /// (see [orderError]).
  Future<SimulatedOrder?> placeOrder({
    required String ticker,
    required SimulatedOrderSide side,
    required double quantity,
    DateTime? tradeDate,
  }) async {
    isPlacingOrder = true;
    orderError = null;
    notifyListeners();

    SimulatedOrder? result;
    try {
      result = await _repository.placeOrder(ticker: ticker, side: side, quantity: quantity, tradeDate: tradeDate);
      portfolio = await _repository.fetchPortfolio();
      await _refreshDerivedState();
    } catch (e) {
      orderError = friendlyErrorMessage(e);
    }

    isPlacingOrder = false;
    notifyListeners();
    return result;
  }

  /// Wipes every simulated position/order and restores the starting virtual
  /// balance. Caller is responsible for confirming with the user first —
  /// this always sends `confirm: true` once called (see
  /// `SimulatedWalletRemoteDataSource.reset`). Returns whether the reset
  /// succeeded.
  Future<bool> resetPortfolio() async {
    isResetting = true;
    resetError = null;
    notifyListeners();

    bool succeeded = false;
    try {
      await _repository.reset();
      portfolio = await _repository.fetchPortfolio();
      await _refreshDerivedState();
      succeeded = true;
    } catch (e) {
      resetError = friendlyErrorMessage(e);
    }

    isResetting = false;
    notifyListeners();
    return succeeded;
  }

  Future<List<AssetQuote>> searchQuotes(String query) {
    if (query.trim().isEmpty) return Future.value(const []);
    return _repository.searchQuotes(query.trim());
  }

  Future<AssetQuote?> fetchQuote(String ticker) => _repository.fetchQuote(ticker);

  /// The close a backdated order for [ticker] on [date] would fill at, or
  /// `null` when no close exists that far back.
  Future<AssetQuote?> fetchQuoteAtDate(String ticker, DateTime date) => _repository.fetchQuoteAtDate(ticker, date);
}
