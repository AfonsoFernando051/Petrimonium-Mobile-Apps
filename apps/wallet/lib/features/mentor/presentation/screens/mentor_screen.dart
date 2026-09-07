import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_colors.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/theme/app_motion.dart';
import 'package:petrimonium/core/utils/formatters.dart';
import 'package:petrimonium/core/utils/pet_assets.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/app_loading_indicator.dart';
import 'package:petrimonium/core/widgets/error_state_view.dart';
import 'package:petrimonium/core/widgets/glass_card.dart';
import 'package:petrimonium/features/mentor/domain/entities/chat_message.dart';
import 'package:petrimonium/features/mentor/presentation/controllers/mentor_chat_controller.dart';
import 'package:petrimonium/features/mentor/presentation/screens/conversation_list_screen.dart';
import 'package:petrimonium/features/mentor/presentation/widgets/chat_bubble.dart';
import 'package:petrimonium/features/mentor/presentation/widgets/mentor_input_bar.dart';
import 'package:petrimonium/features/mentor/presentation/widgets/suggested_prompt_chip.dart';
import 'package:petrimonium/features/mentor/presentation/widgets/typing_indicator.dart';

/// The "Mentor" tab — a full-screen chat with the user's pet acting as their
/// personal investment mentor. Owns its own controller/state (mirrors how
/// `PetShowcase` self-manages its pet fetch) rather than sharing dashboard's
/// portfolio/mascot controllers, since the conversation is self-contained.
class MentorScreen extends StatefulWidget {
  const MentorScreen({super.key, this.initialConversationId});

  /// Opens straight into a past conversation instead of a blank chat — used
  /// by Home's Mentor card ("Por que estou vendo isto?") to resume the exact
  /// conversation its interpretation came from.
  final int? initialConversationId;

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  late final MentorChatController _controller;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _petAsset = PetAssets.imageFor(null);

  @override
  void initState() {
    super.initState();
    _controller = MentorChatController(repository: DI.mentorChatRepository);
    _controller.addListener(_onControllerChanged);
    _controller.loadConversation(widget.initialConversationId);
    _controller.loadSuggestedPrompts();
    DI.mentorChatRepository.purgeLegacyLocalHistory();
    _fetchPetAvatar();
  }

  @override
  void didUpdateWidget(MentorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // DashboardScreen keeps a single MentorScreen instance alive in its
    // IndexedStack — switching tabs alone never re-runs initState, so a new
    // initialConversationId (Home's "Por que estou vendo isto?" link) has to
    // be picked up here instead.
    if (widget.initialConversationId != null &&
        widget.initialConversationId != oldWidget.initialConversationId) {
      _controller.loadConversation(widget.initialConversationId);
    }
  }

  Future<void> _fetchPetAvatar() async {
    try {
      final petData = await DI.petRepository.getMyPet();
      final specie = petData?['specie'] as String?;
      if (specie != null && mounted) {
        setState(() => _petAsset = PetAssets.imageFor(specie));
      }
    } catch (_) {
      // Keep the default avatar — a missing pet image is cosmetic, not fatal.
    }
  }

  void _onControllerChanged() {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _send([String? suggested]) {
    final text = suggested ?? _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    _controller.sendMessage(text, currentScreen: 'mentor');
  }

  Route<T> _fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
                  .animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            ),
          ),
      transitionDuration: AppMotion.pageTransition,
    );
  }

  Future<void> _openHistory() async {
    final result = await Navigator.of(
      context,
    ).push<int?>(_fadeRoute(const ConversationListScreen()));
    if (result == null) return;
    if (result == ConversationListScreen.newConversationSentinel) {
      _controller.startNewChat();
    } else {
      await _controller.loadConversation(result);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _showTypingIndicator {
    if (!_controller.isSending) return false;
    final messages = _controller.messages;
    if (messages.isEmpty) return true;
    final last = messages.last;
    return last.role != ChatRole.mentor || last.text.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildHeader(),
          const SizedBox(height: 12),
          Expanded(child: _buildBody()),
          const SizedBox(height: 8),
          MentorInputBar(
            controller: _textController,
            onSend: _send,
            isSending: _controller.isSending,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // A soft purple/cyan halo behind the Mentor's avatar — Light theme has no
  // cosmic backdrop directly behind the header card, so without this the
  // character reads as a plain chat-app avatar. Dark theme already gets
  // that atmosphere for free from the cosmic background, so it's skipped
  // there rather than doubling up on glow.
  Widget _avatarWithHalo({required Widget avatar, required double haloSize}) {
    if (!context.isDarkMode) {
      return Container(
        width: haloSize,
        height: haloSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.neonPurple.withValues(alpha: 0.22),
              AppColors.neonCyan.withValues(alpha: 0.10),
              AppColors.neonCyan.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: avatar,
      );
    }
    return avatar;
  }

  Widget _buildHeader() {
    final tokens = context.colors;
    return GlassCard(
      borderRadius: 20,
      borderColor: AppColors.neonCyan.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _avatarWithHalo(
            haloSize: 52,
            avatar: CircleAvatar(
              radius: 20,
              backgroundColor: tokens.surface,
              child: ClipOval(
                child: Image.asset(
                  _petAsset,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.pets, color: tokens.textSecondary, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mentor',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Não executa transações · não é consultoria regulada',
                  style: TextStyle(color: tokens.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add_comment_outlined,
              color: tokens.textSecondary,
              size: 20,
            ),
            tooltip: Translator.translate(AppStrings.mentorNewChatTooltip),
            onPressed: _controller.messages.isEmpty
                ? null
                : _controller.startNewChat,
          ),
          IconButton(
            icon: Icon(Icons.history, color: tokens.textSecondary, size: 20),
            tooltip: Translator.translate(AppStrings.mentorHistoryTooltip),
            onPressed: _openHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoadingHistory) {
      return const AppLoadingIndicator();
    }

    if (_controller.historyError != null) {
      return ErrorStateView(
        message: _controller.historyError!,
        onRetry: () => _controller.loadConversation(_controller.conversationId),
      );
    }

    if (_controller.messages.isEmpty) {
      return _buildEmptyState();
    }

    final items = _buildTimelineItems(_controller.messages);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length + (_showTypingIndicator ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const TypingIndicator();
        }
        final item = items[index];
        return item is DateTime ? _DateSeparator(date: item) : ChatBubble(message: item as ChatMessage);
      },
    );
  }

  /// Flattens [messages] into a single render list, inserting a `DateTime`
  /// marker (rendered by [_DateSeparator]) whenever the calendar day changes
  /// — "Hoje" between message groups, per the Mentor chat mockup.
  List<Object> _buildTimelineItems(List<ChatMessage> messages) {
    final items = <Object>[];
    DateTime? lastDay;
    for (final message in messages) {
      final day = DateTime(message.timestamp.year, message.timestamp.month, message.timestamp.day);
      if (lastDay == null || day != lastDay) {
        items.add(day);
        lastDay = day;
      }
      items.add(message);
    }
    return items;
  }

  Widget _buildEmptyState() {
    final tokens = context.colors;
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // 52px halo / 40px avatar — the Wallet design system's "avatar
          // menor" rule (never the Academy's larger 64-118px hero treatment).
          _avatarWithHalo(
            haloSize: 52,
            avatar: CircleAvatar(
              radius: 20,
              backgroundColor: tokens.surface,
              child: ClipOval(
                child: Image.asset(
                  _petAsset,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.pets, color: tokens.textSecondary, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Posso te ajudar a entender sua carteira ou tirar dúvidas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nunca vou comprar, vender ou sugerir uma operação por você.',
            textAlign: TextAlign.center,
            style: TextStyle(color: tokens.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (_controller.suggestedPrompts.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: _controller.suggestedPrompts
                  .map(
                    (prompt) => SuggestedPromptChip(
                      label: prompt,
                      onTap: () => _send(prompt),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final label = date == today
        ? 'Hoje'
        : date == yesterday
            ? 'Ontem'
            : AppFormatters.date(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: context.colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
