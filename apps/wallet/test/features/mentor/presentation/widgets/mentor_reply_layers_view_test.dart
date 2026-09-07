import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/layer_chip.dart';
import 'package:petrimonium/features/mentor/domain/services/wallet_mentor_reply_layers.dart';
import 'package:petrimonium/features/mentor/presentation/widgets/mentor_reply_layers_view.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  /// Collects the rendered markdown source, which is where the reply body ends
  /// up — a leaked `[[DATA]]` marker would show up here.
  List<String> renderedMarkdown(WidgetTester tester) => tester
      .widgetList<MarkdownBody>(find.byType(MarkdownBody))
      .map((w) => w.data)
      .toList();

  group('MentorReplyLayersView', () {
    testWidgets('renders each layer behind its own chip, without the raw markers', (tester) async {
      final layers = WalletMentorReplyLayers.tryParse(
        '[[DATA]] Seu patrimônio é R\$ 1.000,00.'
        '[[CALCULATION]] Alta de 2% no mês.'
        '[[INTERPRETATION]] Isso é consistente com seu objetivo.',
      );
      expect(layers, isNotNull);

      await tester.pumpWidget(wrap(
        MentorReplyLayersView(layers: layers!, timestamp: DateTime(2026, 3, 9, 14, 5)),
      ));

      expect(find.byType(LayerChip), findsNWidgets(3));

      final bodies = renderedMarkdown(tester);
      expect(bodies.length, 3);
      for (final marker in ['[[DATA]]', '[[CALCULATION]]', '[[INTERPRETATION]]']) {
        expect(
          bodies.any((b) => b.contains(marker)),
          isFalse,
          reason: '$marker must be consumed by the parser, never rendered',
        );
      }
      expect(bodies[0], contains('R\$ 1.000,00'));
      expect(bodies[2], contains('consistente'));
    });

    testWidgets('stamps the DADO chip with the reply timestamp', (tester) async {
      final layers = WalletMentorReplyLayers.tryParse('[[DATA]] Saldo estável.')!;

      await tester.pumpWidget(wrap(
        MentorReplyLayersView(layers: layers, timestamp: DateTime(2026, 3, 9, 14, 5)),
      ));

      expect(find.textContaining('09/03 14:05'), findsOneWidget);
    });

    testWidgets('renders only the layers that are present', (tester) async {
      final layers = WalletMentorReplyLayers.tryParse('[[INTERPRETATION]] Só uma leitura.')!;

      await tester.pumpWidget(wrap(
        MentorReplyLayersView(layers: layers, timestamp: DateTime(2026, 3, 9)),
      ));

      expect(find.byType(LayerChip), findsOneWidget);
      expect(renderedMarkdown(tester), ['Só uma leitura.']);
    });
  });
}
