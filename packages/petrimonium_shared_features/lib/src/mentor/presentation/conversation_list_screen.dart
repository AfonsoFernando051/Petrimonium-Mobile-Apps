import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

import '../domain/conversation_store.dart';
import '../domain/conversation_summary.dart';
import 'conversation_list_controller.dart';
import 'conversation_list_tile.dart';

/// Every string this screen shows, supplied by the product.
///
/// A record rather than fifteen constructor parameters: at this size the
/// parameter list stops being readable, and the app builds it in one place
/// right next to the navigation call.
typedef ConversationListCopy = ({
  String historyTitle,
  String newChatLabel,
  String emptyTitle,
  String emptySubtitle,
  String loadError,
  String retryLabel,
  String renameTitle,
  String renameHint,
  String renameSave,
  String renameFailed,
  String deleteTitle,
  String deleteConfirm,
  String deleteButton,
  String deleteFailed,
  String cancelLabel,
});

/// History of the user's Mentor conversations. Popping this screen returns
/// either `null` (nothing selected — user just went back), a positive
/// conversation id (resume that conversation), or the reserved sentinel
/// `-1` (start a brand-new chat), which `MentorScreen` interprets.
class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key, required this.store, required this.copy, required this.background});

  static const int newConversationSentinel = -1;

  final ConversationStore store;
  final ConversationListCopy copy;

  /// Wraps the body in the product's own backdrop. Each app's
  /// `CosmicBackground` paints its own colours and is not shared.
  final Widget Function(Widget child) background;

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  late final ConversationListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConversationListController(repository: widget.store, loadErrorMessage: () => widget.copy.loadError);
    _controller.addListener(_onChanged);
    _controller.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _rename(ConversationSummary conversation) async {
    final controller = TextEditingController(text: conversation.title);
    final tokens = context.colors;
    final accent = context.brand.accent;

    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: tokens.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          widget.copy.renameTitle,
          style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: tokens.textPrimary),
          decoration: InputDecoration(hintText: widget.copy.renameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.copy.cancelLabel, style: TextStyle(color: accent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(widget.copy.renameSave, style: TextStyle(color: accent)),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != conversation.title) {
      final success = await _controller.rename(conversation.id, newTitle);
      if (!success && mounted) {
        GameSnack.show(context, widget.copy.renameFailed, isError: true);
      }
    }
  }

  Future<void> _confirmDelete(ConversationSummary conversation) async {
    final tokens = context.colors;
    final accent = context.brand.accent;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: tokens.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          widget.copy.deleteTitle,
          style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(widget.copy.deleteConfirm, style: TextStyle(color: tokens.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.copy.cancelLabel, style: TextStyle(color: accent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.copy.deleteButton, style: TextStyle(color: tokens.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      unawaited(HapticFeedback.mediumImpact());
      final success = await _controller.delete(conversation.id);
      if (!success && mounted) {
        GameSnack.show(context, widget.copy.deleteFailed, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.copy.historyTitle,
          style: TextStyle(color: tokens.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, ConversationListScreen.newConversationSentinel),
        backgroundColor: context.brand.accentDeep,
        icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
        label: Text(widget.copy.newChatLabel, style: const TextStyle(color: Colors.white)),
      ),
      body: widget.background(SafeArea(child: _buildBody())),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const AppLoadingIndicator();
    }

    if (_controller.error != null) {
      return ErrorStateView(retryLabel: widget.copy.retryLabel, message: _controller.error!, onRetry: _controller.load);
    }

    if (_controller.conversations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 96),
      itemCount: _controller.conversations.length,
      itemBuilder: (context, index) {
        final conversation = _controller.conversations[index];
        return ConversationListTile(
          conversation: conversation,
          renameLabel: widget.copy.renameTitle,
          deleteLabel: widget.copy.deleteButton,
          onTap: () => Navigator.pop(context, conversation.id),
          onRename: () => _rename(conversation),
          onDelete: () => _confirmDelete(conversation),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateView(
      icon: Icons.chat_bubble_outline,
      title: widget.copy.emptyTitle,
      message: widget.copy.emptySubtitle,
    );
  }
}
