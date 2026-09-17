import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_wallet/core/utils/friendly_error_message.dart';
import 'package:petrimonium_wallet/features/mentor/data/repositories/mentor_chat_repository.dart';
import 'package:petrimonium_wallet/features/mentor/domain/entities/chat_message.dart';

/// Which moment of the Mentor stage is on screen. The Mentor tab shows one
/// exchange at a time around the pet instead of a scrolling timeline, so the
/// screen needs "where are we" rather than the raw message list.
enum MentorStagePhase { welcome, thinking, talking }

const String _fallbackErrorReply = 'Hmm, algo deu errado ao pensar na resposta 🐾 Vamos tentar de novo daqui a pouco?';

/// Drives the Mentor chat: which conversation is open, its message list,
/// sending state, and a client-side typewriter reveal that simulates
/// streaming over a normal request/response call (real SSE streaming is a
/// documented future step, not implemented in Phase 1 — see
/// docs/AI_MENTOR.md). `conversationId` is `null` for a fresh/unsaved chat —
/// the backend creates the conversation lazily on the first sent message.
class MentorChatController extends ChangeNotifier with SafeChangeNotifier {
  MentorChatController({required MentorChatRepository repository}) : _repository = repository;

  final MentorChatRepository _repository;

  int? _conversationId;
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  bool _isLoadingHistory = true;
  List<String> _suggestedPrompts = const [];
  String? _topic;
  Timer? _revealTimer;
  String? _revealingMessageId;

  int? get conversationId => _conversationId;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  bool get isLoadingHistory => _isLoadingHistory;
  List<String> get suggestedPrompts => List.unmodifiable(_suggestedPrompts);

  /// The backend's title for the open conversation, shown as the stage card's
  /// topic pill. Only a send returns it — a resumed conversation has none, and
  /// the pill is hidden rather than invented.
  String? get topic => _topic;

  MentorStagePhase get stagePhase {
    if (_messages.isEmpty) return MentorStagePhase.welcome;
    return _messages.last.role == ChatRole.user ? MentorStagePhase.thinking : MentorStagePhase.talking;
  }

  String? get currentQuestion => _lastOf(ChatRole.user)?.text;

  /// `null` while thinking: the reply to the question on stage has not arrived
  /// yet, and an older reply must not stand in for it.
  ChatMessage? get currentReply => stagePhase == MentorStagePhase.talking ? _messages.last : null;

  ChatMessage? _lastOf(ChatRole role) {
    for (final message in _messages.reversed) {
      if (message.role == role) return message;
    }
    return null;
  }

  /// The id of the message currently mid-typewriter-reveal, or `null` when
  /// none is revealing. `MentorScreen` uses this to decide whether the reply
  /// on stage should track [revealingText] instead of its (still empty)
  /// stored text.
  String? get revealingMessageId => _revealingMessageId;

  /// The text revealed so far for [revealingMessageId], updated on every
  /// typewriter tick. Exposed as a `ValueListenable` rather than through
  /// `notifyListeners()` so only the one widget that cares about the
  /// in-progress text rebuilds each tick — the previous approach called
  /// `notifyListeners()` every 16ms, forcing the entire Mentor screen (pet
  /// stage animations included) to rebuild for every few characters revealed.
  final ValueNotifier<String> revealingText = ValueNotifier<String>('');

  /// Set when loading a past conversation's history fails — `MentorScreen`
  /// shows a retry state instead of an indefinite loading spinner.
  String? historyError;

  /// Loads an existing conversation, or clears to a blank/new chat when
  /// [conversationId] is `null`.
  Future<void> loadConversation(int? conversationId) async {
    _revealTimer?.cancel();
    _revealingMessageId = null;
    _conversationId = conversationId;
    _topic = null;
    _messages.clear();
    _isLoadingHistory = conversationId != null;
    historyError = null;
    notifySafely();

    if (conversationId == null) {
      _isLoadingHistory = false;
      notifySafely();
      return;
    }

    try {
      final history = await _repository.loadConversation(conversationId);
      _messages.addAll(history);
    } catch (e) {
      historyError = friendlyErrorMessage(e);
    }

    _isLoadingHistory = false;
    notifySafely();
  }

  Future<void> sendMessage(String text, {String? currentScreen}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    _messages.add(ChatMessage(id: _newId(), role: ChatRole.user, text: trimmed, timestamp: DateTime.now()));
    _isSending = true;
    notifySafely();

    try {
      final result = await _repository.sendMessage(
        message: trimmed,
        conversationId: _conversationId,
        currentScreen: currentScreen,
      );
      _conversationId = result.conversationId;
      _topic = result.title ?? _topic;
      await _revealReply(result.reply, isError: false, sources: result.sources);
    } catch (e, stackTrace) {
      // Logged rather than silently discarded — a swallowed exception here
      // means the debug console shows nothing when a request fails, which
      // made a real production issue (backend RestTemplate timeout cutting
      // off Claude's reply) far harder to diagnose than it needed to be.
      debugPrint('MentorChatController.sendMessage failed: $e\n$stackTrace');
      await _revealReply(_fallbackErrorReply, isError: true);
    } finally {
      _isSending = false;
      notifySafely();
    }
  }

  Future<void> loadSuggestedPrompts() async {
    try {
      _suggestedPrompts = await _repository.loadSuggestedPrompts();
      notifySafely();
    } catch (e) {
      debugPrint('Mentor suggestions unavailable: $e');
    }
  }

  /// Reveals [fullText] a few characters at a time so a normal (non-streamed)
  /// backend reply still reads as "typing" like the ChatGPT/Claude-style
  /// experience the product spec asks for.
  Future<void> _revealReply(String fullText, {required bool isError, List<String> sources = const []}) async {
    final messageId = _newId();
    _messages.add(
      ChatMessage(
        id: messageId,
        role: ChatRole.mentor,
        text: '',
        timestamp: DateTime.now(),
        isError: isError,
        sources: sources,
      ),
    );
    notifySafely();

    if (fullText.isEmpty) return;

    _revealingMessageId = messageId;
    revealingText.value = '';

    final completer = Completer<void>();
    var charIndex = 0;
    const chunkSize = 3;
    const tickDuration = Duration(milliseconds: 16);

    _revealTimer?.cancel();
    _revealTimer = Timer.periodic(tickDuration, (timer) {
      charIndex = min(charIndex + chunkSize, fullText.length);
      // Ticks update only this notifier, not notifyListeners() — the whole
      // Mentor screen must not rebuild on every character chunk. Only the
      // ValueListenableBuilder tracking revealingText reacts per tick.
      revealingText.value = fullText.substring(0, charIndex);

      if (charIndex >= fullText.length) {
        timer.cancel();
        final index = _messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(text: fullText);
        }
        _revealingMessageId = null;
        notifySafely();
        if (!completer.isCompleted) completer.complete();
      }
    });

    return completer.future;
  }

  /// Resets to a blank, unsaved chat — no backend call. Nothing is lost:
  /// every message already sent was persisted server-side the moment it was
  /// sent. Resuming a past conversation, or deleting one, happens from the
  /// separate conversation history screen.
  void startNewChat() {
    _revealTimer?.cancel();
    _revealingMessageId = null;
    _conversationId = null;
    _topic = null;
    _messages.clear();
    unawaited(loadSuggestedPrompts());
    notifySafely();
  }

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_messages.length}';

  @override
  void dispose() {
    _revealTimer?.cancel();
    revealingText.dispose();
    super.dispose();
  }
}
