import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import '../../test_theme.dart';

class MockConversationStore extends Mock implements ConversationStore {}

/// This product-agnostic copy stands in for whatever an app would resolve
/// through its translator; the assertions below are the same strings the
/// app-local version of this test asserted.
const ConversationListCopy testCopy = (
  historyTitle: 'Conversas',
  newChatLabel: 'Nova conversa',
  emptyTitle: 'Nenhuma conversa ainda',
  emptySubtitle: 'Suas conversas com o mentor vão aparecer aqui.',
  loadError: 'Não foi possível carregar suas conversas.',
  retryLabel: 'Tentar novamente',
  renameTitle: 'Renomear conversa',
  renameHint: 'Título da conversa',
  renameSave: 'Salvar',
  renameFailed: 'Não foi possível renomear a conversa. Tente novamente.',
  deleteTitle: 'Apagar conversa?',
  deleteConfirm: 'Esta conversa e todas as mensagens serão apagadas permanentemente.',
  deleteButton: 'Apagar',
  deleteFailed: 'Não foi possível apagar a conversa. Tente novamente.',
  cancelLabel: 'Cancelar',
);

void main() {
  late MockConversationStore mockRepository;

  setUp(() {
    mockRepository = MockConversationStore();
  });

  // The backdrop is each product's own `CosmicBackground` and is not part of
  // this package; an identity wrapper keeps the widget tree the assertions
  // care about unchanged.
  ConversationListScreen screen() =>
      ConversationListScreen(store: mockRepository, copy: testCopy, background: (child) => child);

  Widget buildTestableWidget() {
    return MaterialApp(theme: TestTheme.dark, home: screen());
  }

  group('ConversationListScreen', () {
    testWidgets('shows a loading indicator before the initial load resolves', (WidgetTester tester) async {
      when(() => mockRepository.listConversations()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return <ConversationSummary>[];
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(AppLoadingIndicator), findsOneWidget);

      // Flush the mocked repository's 50ms delayed Future before the test
      // ends — otherwise its Timer is still pending at teardown and
      // flutter_test's "no pending Timer" invariant fails the test.
      await tester.pump(const Duration(milliseconds: 60));
    });

    testWidgets('shows an empty state when there are no conversations', (WidgetTester tester) async {
      when(() => mockRepository.listConversations()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Nenhuma conversa ainda'), findsOneWidget);
      expect(find.text('Suas conversas com o mentor vão aparecer aqui.'), findsOneWidget);
    });

    testWidgets('shows an error view with retry when the load fails', (WidgetTester tester) async {
      when(() => mockRepository.listConversations()).thenThrow(Exception('backend down'));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Não foi possível carregar suas conversas.'), findsOneWidget);
    });

    testWidgets('renders one tile per conversation', (WidgetTester tester) async {
      when(() => mockRepository.listConversations()).thenAnswer(
        (_) async => [
          ConversationSummary(id: 1, title: 'Dividendos', updatedAt: DateTime(2024, 1, 1)),
          ConversationSummary(id: 2, title: 'ETFs', updatedAt: DateTime(2024, 1, 2)),
        ],
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ConversationListTile), findsNWidgets(2));
      expect(find.text('Dividendos'), findsOneWidget);
      expect(find.text('ETFs'), findsOneWidget);
    });

    testWidgets('tapping a conversation pops the screen with its id', (WidgetTester tester) async {
      when(
        () => mockRepository.listConversations(),
      ).thenAnswer((_) async => [ConversationSummary(id: 42, title: 'Dividendos', updatedAt: DateTime(2024, 1, 1))]);

      int? poppedValue;
      await tester.pumpWidget(
        MaterialApp(
          theme: TestTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    poppedValue = await Navigator.of(context).push<int?>(MaterialPageRoute(builder: (_) => screen()));
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Dividendos'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(poppedValue, 42);
    });

    testWidgets('tapping the new-chat FAB pops the screen with the newConversationSentinel', (
      WidgetTester tester,
    ) async {
      when(() => mockRepository.listConversations()).thenAnswer((_) async => []);

      int? poppedValue;
      await tester.pumpWidget(
        MaterialApp(
          theme: TestTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    poppedValue = await Navigator.of(context).push<int?>(MaterialPageRoute(builder: (_) => screen()));
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Nova conversa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(poppedValue, ConversationListScreen.newConversationSentinel);
    });

    testWidgets('renaming a conversation calls the repository and updates the tile', (WidgetTester tester) async {
      // ConversationListController.rename() re-fetches via
      // listConversations() after renaming (no optimistic local update), so
      // the stub must reflect the new title on the second call.
      var title = 'Dividendos';
      when(
        () => mockRepository.listConversations(),
      ).thenAnswer((_) async => [ConversationSummary(id: 1, title: title, updatedAt: DateTime(2024, 1, 1))]);
      when(() => mockRepository.renameConversation(1, 'Ações')).thenAnswer((_) async {
        title = 'Ações';
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Rename/delete are only reachable via the tile's overflow menu (see
      // ConversationListTile), not standalone icons on the tile itself.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Renomear conversa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Ações');
      await tester.tap(find.text('Salvar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockRepository.renameConversation(1, 'Ações')).called(1);
      expect(find.text('Ações'), findsOneWidget);
    });

    testWidgets('deleting a conversation calls the repository and removes the tile', (WidgetTester tester) async {
      when(
        () => mockRepository.listConversations(),
      ).thenAnswer((_) async => [ConversationSummary(id: 1, title: 'Dividendos', updatedAt: DateTime(2024, 1, 1))]);
      when(() => mockRepository.deleteConversation(1)).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Rename/delete are only reachable via the tile's overflow menu (see
      // ConversationListTile), not standalone icons on the tile itself.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Apagar')); // "Apagar" menu item

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scoped to the AlertDialog: the popup menu's own "Apagar" item can
      // still be mid-dismiss-animation and present in the tree alongside
      // the confirm dialog's identically-labeled button.
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Apagar')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockRepository.deleteConversation(1)).called(1);
      expect(find.byType(ConversationListTile), findsNothing);
      expect(find.text('Nenhuma conversa ainda'), findsOneWidget);
    });
  });
}
