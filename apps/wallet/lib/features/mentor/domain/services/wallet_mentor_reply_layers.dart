/// Splits a Mentor chat reply into its "dado" (raw fact), "cálculo"
/// (deterministic computation) and "interpretação" (the Mentor's own read)
/// layers, per the three-marker format the Wallet system prompt asks the
/// model to use when a reply touches the user's real portfolio (see the
/// backend's `MentorSystemPromptBuilder.WALLET_STRUCTURED_RESPONSE_INSTRUCTION`)
/// — fixed English markers regardless of the reply's own language, so
/// parsing doesn't need a per-language table.
///
/// All three segments are optional and independent: a reply might state a
/// fact with no computation, compute something with no interpretation
/// layered on, or skip every marker entirely (a greeting, a general
/// question) — [tryParse] returns `null` when none of the markers appear,
/// so the caller renders the raw text as before rather than fabricating a
/// layer split that isn't there.
class WalletMentorReplyLayers {
  const WalletMentorReplyLayers({this.data, this.calculation, this.interpretation});

  final String? data;
  final String? calculation;
  final String? interpretation;

  static const _dataMarker = '[[DATA]]';
  static const _calculationMarker = '[[CALCULATION]]';
  static const _interpretationMarker = '[[INTERPRETATION]]';

  static WalletMentorReplyLayers? tryParse(String text) {
    final positions = <(int start, int markerLength, String key)>[];
    for (final (marker, key) in [
      (_dataMarker, 'data'),
      (_calculationMarker, 'calculation'),
      (_interpretationMarker, 'interpretation'),
    ]) {
      final start = text.indexOf(marker);
      if (start != -1) positions.add((start, marker.length, key));
    }
    positions.sort((a, b) => a.$1.compareTo(b.$1));

    if (positions.isEmpty) return null;

    String? data;
    String? calculation;
    String? interpretation;

    for (var i = 0; i < positions.length; i++) {
      final (start, markerLength, key) = positions[i];
      final contentStart = start + markerLength;
      final contentEnd = i + 1 < positions.length ? positions[i + 1].$1 : text.length;
      final content = text.substring(contentStart, contentEnd).trim();
      if (content.isEmpty) continue;

      switch (key) {
        case 'data':
          data = content;
        case 'calculation':
          calculation = content;
        case 'interpretation':
          interpretation = content;
      }
    }

    if (data == null && calculation == null && interpretation == null) return null;
    return WalletMentorReplyLayers(data: data, calculation: calculation, interpretation: interpretation);
  }
}
