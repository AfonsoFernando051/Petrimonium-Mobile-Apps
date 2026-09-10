import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import '../../test_theme.dart';

void main() {
  Widget buildTestableWidget({
    required ConversationSummary conversation,
    VoidCallback? onTap,
    VoidCallback? onRename,
    VoidCallback? onDelete,
  }) {
    return MaterialApp(
      theme: TestTheme.dark,
      home: Scaffold(
        body: ConversationListTile(
          conversation: conversation,
          renameLabel: 'Renomear conversa',
          deleteLabel: 'Apagar',
          onTap: onTap ?? () {},
          onRename: onRename ?? () {},
          onDelete: onDelete ?? () {},
        ),
      ),
    );
  }

  group('ConversationListTile', () {
    testWidgets('renders the title and last message preview when present', (tester) async {
      final conversation = ConversationSummary(
        id: 1,
        title: 'Dividendos',
        updatedAt: DateTime.now(),
        lastMessagePreview: 'Claro, posso ajudar!',
      );

      await tester.pumpWidget(buildTestableWidget(conversation: conversation));

      expect(find.text('Dividendos'), findsOneWidget);
      expect(find.text('Claro, posso ajudar!'), findsOneWidget);
    });

    testWidgets('renders "..." when the title is empty', (tester) async {
      final conversation = ConversationSummary(id: 1, title: '', updatedAt: DateTime.now());

      await tester.pumpWidget(buildTestableWidget(conversation: conversation));

      expect(find.text('...'), findsOneWidget);
    });

    testWidgets('omits the preview line when lastMessagePreview is null', (tester) async {
      final conversation = ConversationSummary(id: 1, title: 'Dividendos', updatedAt: DateTime.now());

      await tester.pumpWidget(buildTestableWidget(conversation: conversation));

      expect(find.text('Dividendos'), findsOneWidget);
      // Only the title Text should exist inside the tile's text column.
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows "agora" for a just-now update', (tester) async {
      final conversation = ConversationSummary(id: 1, title: 'x', updatedAt: DateTime.now());

      await tester.pumpWidget(buildTestableWidget(conversation: conversation));

      expect(find.text('agora'), findsOneWidget);
    });

    testWidgets('tapping the tile invokes onTap', (tester) async {
      var tapped = false;
      final conversation = ConversationSummary(id: 1, title: 'Dividendos', updatedAt: DateTime.now());

      await tester.pumpWidget(buildTestableWidget(conversation: conversation, onTap: () => tapped = true));

      // .first: the tile's own InkWell (wrapping the whole row) is the
      // outer one; PopupMenuButton's icon renders a second, inner InkWell,
      // so byType(InkWell) alone is ambiguous.
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('selecting "rename" from the popup menu invokes onRename', (tester) async {
      var renamed = false;
      final conversation = ConversationSummary(id: 1, title: 'Dividendos', updatedAt: DateTime.now());

      await tester.pumpWidget(buildTestableWidget(conversation: conversation, onRename: () => renamed = true));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Renomear conversa'));
      await tester.pumpAndSettle();

      expect(renamed, isTrue);
    });

    testWidgets('selecting "delete" from the popup menu invokes onDelete', (tester) async {
      var deleted = false;
      final conversation = ConversationSummary(id: 1, title: 'Dividendos', updatedAt: DateTime.now());

      await tester.pumpWidget(buildTestableWidget(conversation: conversation, onDelete: () => deleted = true));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('takes its border accent from the product theme, not a baked-in colour', (tester) async {
      // `AppColors.neonCyan` is cyan in Academy and emerald in Wallet. This
      // tile used to read it directly; it now reads `context.brand.accent`,
      // which is that same field in each app's palette.
      final conversation = ConversationSummary(id: 1, title: 'Dividendos', updatedAt: DateTime.now());

      await tester.pumpWidget(buildTestableWidget(conversation: conversation));

      final card = tester.widget<GlassCard>(find.byType(GlassCard));
      expect(card.borderColor, TestPalette.accents.accent.withValues(alpha: 0.2));
    });
  });
}
