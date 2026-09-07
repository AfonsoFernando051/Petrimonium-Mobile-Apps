import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium/features/mentor/domain/services/wallet_mentor_reply_layers.dart';

void main() {
  group('WalletMentorReplyLayers.tryParse', () {
    test('returns null when no markers are present', () {
      expect(WalletMentorReplyLayers.tryParse('Oi! Posso te ajudar com sua carteira.'), isNull);
    });

    test('returns null for an empty string', () {
      expect(WalletMentorReplyLayers.tryParse(''), isNull);
    });

    test('parses a data-only reply', () {
      final layers = WalletMentorReplyLayers.tryParse(
        '[[DATA]]\nSuas ações e FIIs desvalorizaram no período.',
      );

      expect(layers, isNotNull);
      expect(layers!.data, 'Suas ações e FIIs desvalorizaram no período.');
      expect(layers.calculation, isNull);
      expect(layers.interpretation, isNull);
    });

    test('parses all three layers in order', () {
      final layers = WalletMentorReplyLayers.tryParse(
        '[[DATA]]\nNo período, suas ações e FIIs desvalorizaram no total.\n'
        '[[CALCULATION]]\n- R\$ 812,40 (-1,7%) no mês\n'
        '[[INTERPRETATION]]\nIsso é normal em mercados voláteis — sua composição segue parecida.',
      );

      expect(layers, isNotNull);
      expect(layers!.data, 'No período, suas ações e FIIs desvalorizaram no total.');
      expect(layers.calculation, r'- R$ 812,40 (-1,7%) no mês');
      expect(layers.interpretation, 'Isso é normal em mercados voláteis — sua composição segue parecida.');
    });

    test('handles markers out of the documented order', () {
      final layers = WalletMentorReplyLayers.tryParse(
        '[[INTERPRETATION]]\nMinha leitura.\n[[DATA]]\nO fato.',
      );

      expect(layers, isNotNull);
      expect(layers!.interpretation, 'Minha leitura.');
      expect(layers.data, 'O fato.');
    });

    test('skips a marker with no content after it (progressive reveal mid-stream)', () {
      final layers = WalletMentorReplyLayers.tryParse('[[DATA]]\nO fato real.\n[[CALCULATION]]');

      expect(layers, isNotNull);
      expect(layers!.data, 'O fato real.');
      expect(layers.calculation, isNull);
    });

    test('a reply with only whitespace after every marker is treated as having no layers', () {
      expect(WalletMentorReplyLayers.tryParse('[[DATA]]   \n[[CALCULATION]]  '), isNull);
    });
  });
}
