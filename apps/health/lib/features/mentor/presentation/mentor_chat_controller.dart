import '../../../core/i18n/locale_controller.dart';
import '../../health/data/health_repository.dart';
import '../../health/domain/mentor_models.dart';

/// The Mentor conversation: its messages, the suggestion chips, and the
/// in-flight/error state of a reply.
///
/// Split out of `HealthController` so that the Mentor's state is not
/// interleaved with the user's accounts and transactions. Deliberately not a
/// `ChangeNotifier`: `HealthController` owns the single notifier the widget
/// tree listens to (see `HealthScope`), so this reports through [onChanged]
/// and nothing about when widgets rebuild changes.
final class MentorChatController {
  MentorChatController({
    required HealthRepository repository,
    required LocaleController localeController,
    required void Function() onChanged,
  }) : _repository = repository,
       _localeController = localeController,
       _onChanged = onChanged;

  final HealthRepository _repository;
  final LocaleController _localeController;
  final void Function() _onChanged;

  List<ChatMessage> messages = const [];
  int? conversationId;
  List<String> suggestions = const [];
  bool busy = false;
  String? error;

  Future<void> loadSuggestions() async {
    try {
      final language = _localeController.current.tag.split('-').first;
      suggestions = await _repository.getMentorSuggestions(language: language);
    } catch (_) {
      suggestions = const [];
    }
    _onChanged();
  }

  void startNewConversation() {
    conversationId = null;
    messages = const [];
    error = null;
    _onChanged();
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || busy) return;
    final userMessage = ChatMessage(
      id: 'u-${DateTime.now().microsecondsSinceEpoch}',
      author: ChatAuthor.user,
      text: trimmed,
    );
    messages = [...messages, userMessage];
    busy = true;
    error = null;
    _onChanged();
    try {
      final reply = await _repository.sendMentorMessage(message: trimmed, conversationId: conversationId);
      conversationId = reply.conversationId;
      messages = [
        ...messages,
        ChatMessage(
          id: 'm-${DateTime.now().microsecondsSinceEpoch}',
          author: ChatAuthor.mentor,
          text: reply.reply,
          sources: reply.sources,
        ),
      ];
    } catch (exception) {
      error = exception.toString();
    } finally {
      busy = false;
      _onChanged();
    }
  }

  void toggleWhy(String messageId) {
    for (final message in messages) {
      if (message.id == messageId) {
        message.whyOpen = !message.whyOpen;
        break;
      }
    }
    _onChanged();
  }

  /// Cleared on sign-out. Suggestions are not: they are language-scoped copy,
  /// not the previous account's data — matching what `logout()` cleared
  /// before this split.
  void reset() {
    messages = const [];
    conversationId = null;
  }
}
