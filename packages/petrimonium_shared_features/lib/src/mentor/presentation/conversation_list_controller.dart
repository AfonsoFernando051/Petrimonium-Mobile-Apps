import 'package:flutter/foundation.dart';

import '../domain/conversation_store.dart';
import '../domain/conversation_summary.dart';

/// Drives the Mentor conversation history screen: load, rename, delete.
class ConversationListController extends ChangeNotifier {
  ConversationListController({required ConversationStore repository, required String Function() loadErrorMessage})
    : _repository = repository,
      _loadErrorMessage = loadErrorMessage;

  final ConversationStore _repository;

  /// Resolved at the moment of failure rather than taken as a plain string, so
  /// the message still lands in the language the user is reading *now* — the
  /// app-local version called its translator here for the same reason.
  final String Function() _loadErrorMessage;

  bool isLoading = true;
  String? error;
  List<ConversationSummary> conversations = [];

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      conversations = await _repository.listConversations();
    } catch (_) {
      error = _loadErrorMessage();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Returns whether the rename succeeded — callers show a translated
  /// failure snackbar when it doesn't, since the dialog has already closed
  /// by the time this runs and nothing else would tell the user it failed.
  Future<bool> rename(int conversationId, String title) async {
    try {
      await _repository.renameConversation(conversationId, title);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Same contract as [rename].
  Future<bool> delete(int conversationId) async {
    try {
      await _repository.deleteConversation(conversationId);
      conversations = conversations.where((c) => c.id != conversationId).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
