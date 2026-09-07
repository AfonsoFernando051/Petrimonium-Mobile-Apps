/// The real "o que mudou" split for a trailing window (Home shows the
/// trailing 30 days): [valorizacao] is the portion of the period's total
/// value change not explained by new contributions (market movement on
/// already- and newly-held positions), [aportes] is new capital committed
/// via lots purchased within the window, and [rendimentos] is real
/// confirmed dividend/JCP/rendimento income paid within the window.
///
/// Never a fabricated or backend-sourced-but-nonexistent field — computed
/// client-side from the same lot data `WealthHistoryCalculator` already
/// turns into the Wealth Evolution chart, plus the real `DividendRadar`
/// history (see `PortfolioController.wealthChange30d`).
class WealthChangeBreakdown {
  final double valorizacao;
  final double aportes;
  final double rendimentos;

  const WealthChangeBreakdown({
    required this.valorizacao,
    required this.aportes,
    required this.rendimentos,
  });
}
