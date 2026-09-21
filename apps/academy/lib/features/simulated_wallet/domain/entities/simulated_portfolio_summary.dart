import 'package:petrimonium_academy/features/simulated_wallet/domain/entities/simulated_position.dart';

/// The user's simulation wallet — only the positions they added themselves,
/// with no starting balance or cash of any kind. Never derived from, or
/// connected to, any real brokerage/bank/exchange account. Mirrors the
/// backend's `SimulatedPortfolioSummaryDTO`.
class SimulatedPortfolioSummary {
  final String currency;
  final DateTime? resetAt;
  final List<SimulatedPosition> positions;

  const SimulatedPortfolioSummary({required this.currency, required this.resetAt, required this.positions});

  static const empty = SimulatedPortfolioSummary(currency: 'BRL', resetAt: null, positions: []);

  factory SimulatedPortfolioSummary.fromJson(Map<String, dynamic> json) {
    final rawPositions = json['positions'] as List<dynamic>? ?? const [];
    return SimulatedPortfolioSummary(
      currency: json['currency'] as String? ?? 'BRL',
      resetAt: json['resetAt'] == null ? null : DateTime.parse(json['resetAt'] as String),
      positions: rawPositions.cast<Map<String, dynamic>>().map(SimulatedPosition.fromJson).toList(),
    );
  }
}
