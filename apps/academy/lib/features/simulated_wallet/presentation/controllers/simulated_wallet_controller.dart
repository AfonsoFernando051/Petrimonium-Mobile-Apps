import 'package:flutter/foundation.dart';
import 'package:petrimonium_academy/core/utils/friendly_error_message.dart';
import 'package:petrimonium_academy/features/simulated_wallet/data/repositories/simulated_wallet_repository.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/asset_quote.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_order_side.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_portfolio_summary.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_position.dart';
import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_position_quote.dart';

/// Owns all state for the simulated wallet (Academy's fictitious "Carteira"
/// tab) — entirely separate from `PortfolioController`, which still owns
/// the real-portfolio-flavored gamification orchestration (achievements/
/// missions/XP) until that's untangled in a later pass. This controller
/// never touches `PortfolioRepository`/`InvestmentRepository` or any
/// real_portfolio endpoint.
class SimulatedWalletController extends ChangeNotifier {
  SimulatedWalletController({required SimulatedWalletRepository repository}) : _repository = repository;

  final SimulatedWalletRepository _repository;

  bool isLoading = true;
  String? error;
  SimulatedPortfolioSummary portfolio = SimulatedPortfolioSummary.empty;

  /// Each held position paired with its current market price, fetched right
  /// after [portfolio] — this is what makes "how much can I gain or lose"
  /// answerable at all, since the portfolio summary itself carries only cost
  /// basis (see `SimulatedPositionQuote`'s class doc). Stays in lockstep with
  /// [portfolio.positions]: recomputed by every call that reloads it.
  List<SimulatedPositionQuote> positionQuotes = [];

  bool isPlacingOrder = false;
  String? orderError;

  bool isResetting = false;
  String? resetError;

  /// Sum of every position's cost basis — "quanto foi investido", the
  /// denominator for [totalProfitPercent].
  double get totalCostBasis => portfolio.positions.fold(0.0, (sum, p) => sum + p.costBasis);

  /// Sum of every position's current value, falling back to its cost basis
  /// where the quote is unavailable (see [SimulatedPositionQuote.valueOrCostBasis]).
  double get totalPositionsValue => positionQuotes.fold(0.0, (sum, q) => sum + q.valueOrCostBasis);

  /// Virtual cash still uninvested, plus every position at its current
  /// (or, failing that, cost) value — the single "patrimônio total" figure.
  double get totalPatrimony => portfolio.virtualBalance + totalPositionsValue;

  /// Unrealized gain/loss across every position with a known price. A
  /// position with no quote contributes zero here (neither a gain nor a
  /// loss), never a fabricated figure.
  double get totalProfit => totalPositionsValue - totalCostBasis;

  double get totalProfitPercent => totalCostBasis == 0 ? 0 : (totalProfit / totalCostBasis) * 100;

  Future<void> loadPortfolio() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      portfolio = await _repository.fetchPortfolio();
      positionQuotes = await _fetchPositionQuotes(portfolio.positions);
    } catch (e) {
      error = friendlyErrorMessage(e);
    }

    isLoading = false;
    notifyListeners();
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

  Future<void> refresh() => loadPortfolio();

  /// Places a simulated order and reloads the portfolio on success so the
  /// new balance/position is immediately reflected. Returns the created
  /// order, or `null` if the placement failed (see [orderError]).
  Future<SimulatedOrder?> placeOrder({
    required String ticker,
    required SimulatedOrderSide side,
    required double quantity,
  }) async {
    isPlacingOrder = true;
    orderError = null;
    notifyListeners();

    SimulatedOrder? result;
    try {
      result = await _repository.placeOrder(ticker: ticker, side: side, quantity: quantity);
      portfolio = await _repository.fetchPortfolio();
      positionQuotes = await _fetchPositionQuotes(portfolio.positions);
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
      positionQuotes = await _fetchPositionQuotes(portfolio.positions);
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
}
