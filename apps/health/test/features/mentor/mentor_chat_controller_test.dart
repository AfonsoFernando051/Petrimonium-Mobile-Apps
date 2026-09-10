import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium_health/core/i18n/locale_controller.dart';
import 'package:petrimonium_health/features/health/data/health_repository.dart';
import 'package:petrimonium_health/features/health/domain/mentor_models.dart';
import 'package:petrimonium_health/features/mentor/presentation/mentor_chat_controller.dart';

/// The Mentor conversation used to be five fields on `HealthController`,
/// interleaved with the user's accounts. These pin the behaviour that moved.
void main() {
  late _Repository repository;
  late int notifications;
  late MentorChatController mentor;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    repository = _Repository();
    notifications = 0;
    mentor = MentorChatController(
      repository: repository,
      localeController: LocaleController(),
      onChanged: () => notifications++,
    );
  });

  test('sending appends the user message before the reply arrives', () async {
    final pending = mentor.send('Como reduzo minha dívida?');

    expect(mentor.messages, hasLength(1), reason: 'the question is on screen while the reply is in flight');
    expect(mentor.messages.single.author, ChatAuthor.user);
    expect(mentor.busy, isTrue);

    repository.completeWith(
      const MentorReply(
        reply: 'Comece pela dívida de maior juro.',
        conversationId: 42,
        title: null,
        sources: ['cartilha-bcb'],
      ),
    );
    await pending;

    expect(mentor.messages, hasLength(2));
    expect(mentor.messages.last.author, ChatAuthor.mentor);
    expect(mentor.messages.last.sources, ['cartilha-bcb']);
    expect(mentor.conversationId, 42, reason: 'the next message continues the same conversation');
    expect(mentor.busy, isFalse);
    expect(mentor.error, isNull);
  });

  test('an empty or whitespace-only message is not sent', () async {
    await mentor.send('   ');

    expect(mentor.messages, isEmpty);
    expect(repository.sendCalls, 0);
    expect(notifications, 0);
  });

  test('a second send while one is in flight is dropped', () async {
    final first = mentor.send('primeira');
    await mentor.send('segunda');

    expect(repository.sendCalls, 1, reason: 'busy guards against a double-tap sending twice');

    repository.completeWith(const MentorReply(reply: 'ok', conversationId: 1, title: null, sources: []));
    await first;
  });

  test('a failed reply surfaces the error and stops being busy', () async {
    final pending = mentor.send('pergunta');
    repository.failWith(Exception('network down'));
    await pending;

    expect(mentor.busy, isFalse);
    expect(mentor.error, contains('network down'));
    expect(mentor.messages, hasLength(1), reason: 'the question stays; no mentor bubble was produced');
  });

  test('suggestions that fail to load leave an empty list rather than an error', () async {
    repository.suggestionsThrow = true;

    await mentor.loadSuggestions();

    expect(mentor.suggestions, isEmpty);
    expect(mentor.error, isNull, reason: 'chips are optional garnish, not a failure the user must see');
  });

  test('starting a new conversation clears the transcript and the thread id', () async {
    final pending = mentor.send('oi');
    repository.completeWith(const MentorReply(reply: 'olá', conversationId: 7, title: null, sources: []));
    await pending;

    mentor.startNewConversation();

    expect(mentor.messages, isEmpty);
    expect(mentor.conversationId, isNull);
    expect(mentor.error, isNull);
  });

  test('toggleWhy flips only the message named', () async {
    final pending = mentor.send('pergunta');
    repository.completeWith(const MentorReply(reply: 'resposta', conversationId: 1, title: null, sources: ['a']));
    await pending;

    final target = mentor.messages.last;
    mentor.toggleWhy(target.id);

    expect(target.whyOpen, isTrue);
    expect(mentor.messages.first.whyOpen, isFalse);
  });

  test('reset clears the transcript but keeps the suggestion chips', () async {
    repository.suggestions = ['Como poupar?'];
    await mentor.loadSuggestions();
    final pending = mentor.send('oi');
    repository.completeWith(const MentorReply(reply: 'olá', conversationId: 3, title: null, sources: []));
    await pending;

    mentor.reset();

    expect(mentor.messages, isEmpty);
    expect(mentor.conversationId, isNull);
    expect(mentor.suggestions, [
      'Como poupar?',
    ], reason: 'chips are language-scoped copy, not the previous account\'s data');
  });
}

class _Repository implements HealthRepository {
  int sendCalls = 0;
  bool suggestionsThrow = false;
  List<String> suggestions = const [];
  Completer<MentorReply>? _pending;

  void completeWith(MentorReply reply) => _pending!.complete(reply);
  void failWith(Object error) => _pending!.completeError(error);

  @override
  Future<List<String>> getMentorSuggestions({String language = 'pt', int limit = 5}) async {
    if (suggestionsThrow) throw Exception('offline');
    return suggestions;
  }

  @override
  Future<MentorReply> sendMentorMessage({required String message, int? conversationId}) {
    sendCalls++;
    _pending = Completer<MentorReply>();
    return _pending!.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
