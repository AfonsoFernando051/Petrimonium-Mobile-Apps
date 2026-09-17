import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import 'package:petrimonium_wallet/features/mentor/presentation/conversation_list_route.dart';
import 'package:flutter/material.dart';
import 'package:petrimonium_wallet/core/constants/app_colors.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/utils/display_name.dart';
import 'package:petrimonium_wallet/core/utils/pet_assets.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/mentor/presentation/controllers/mentor_chat_controller.dart';
import 'package:petrimonium_wallet/features/mentor/presentation/widgets/mentor_pet_stage.dart';
import 'package:petrimonium_wallet/features/mentor/presentation/widgets/mentor_speech_card.dart';

/// The "Mentor" tab — the user's pet as their personal investment mentor.
/// One exchange at a time around the pet (welcome → thinking → talking)
/// instead of a scrolling chat timeline; earlier exchanges live in the
/// conversation history. Owns its own controller/state (mirrors how
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

  String _petAsset = PetAssets.imageFor(null);
  String? _displayName;
  bool _infoOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = MentorChatController(repository: DI.mentorChatRepository);
    _controller.addListener(_onControllerChanged);
    _controller.loadConversation(widget.initialConversationId);
    _controller.loadSuggestedPrompts();
    DI.mentorChatRepository.purgeLegacyLocalHistory();
    _fetchPetAvatar();
    _loadDisplayName();
  }

  @override
  void didUpdateWidget(MentorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // DashboardScreen keeps a single MentorScreen instance alive in its
    // IndexedStack — switching tabs alone never re-runs initState, so a new
    // initialConversationId (Home's "Por que estou vendo isto?" link) has to
    // be picked up here instead.
    if (widget.initialConversationId != null && widget.initialConversationId != oldWidget.initialConversationId) {
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

  Future<void> _loadDisplayName() async {
    final name = deriveDisplayNameFromEmail(await DI.authRepository.getSavedEmail());
    if (!mounted || name == null) return;
    setState(() => _displayName = name);
  }

  void _onControllerChanged() => setState(() {});

  void _send([String? suggested]) {
    final text = suggested ?? _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    _controller.sendMessage(text, currentScreen: 'mentor');
  }

  Route<T> _fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      transitionDuration: AppMotion.pageTransition,
    );
  }

  Future<void> _openHistory() async {
    final result = await Navigator.of(context).push<int?>(_fadeRoute(buildConversationListScreen()));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
          const SizedBox(height: 8),
          MentorInputBar(
            controller: _textController,
            onSend: _send,
            isSending: _controller.isSending,
            hintText: Translator.translate(AppStrings.mentorStageInputHint),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final tokens = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.neonCyan.withValues(alpha: 0.28), AppColors.neonCyan.withValues(alpha: 0)],
                  stops: const [0.0, 0.7],
                ),
              ),
              child: Image.asset(
                _petAsset,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(Icons.pets, color: tokens.textSecondary, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mentor',
                    style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    Translator.translate(AppStrings.mentorStageSubtitle),
                    style: TextStyle(color: tokens.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.schedule, color: tokens.textSecondary, size: 19),
              tooltip: Translator.translate(AppStrings.mentorHistoryTooltip),
              onPressed: _openHistory,
            ),
            IconButton(
              icon: Icon(Icons.info_outline, color: tokens.textSecondary, size: 19),
              tooltip: Translator.translate(AppStrings.mentorStageInfoTooltip),
              onPressed: () => setState(() => _infoOpen = !_infoOpen),
            ),
          ],
        ),
        if (_infoOpen)
          Positioned(
            top: 42,
            right: 0,
            width: 230,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.borderStrong),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 12)),
                ],
              ),
              child: Text(
                Translator.translate(AppStrings.mentorStageDisclaimer),
                style: TextStyle(color: tokens.textSecondary, fontSize: 11.5, height: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_controller.isLoadingHistory) {
      return const AppLoadingIndicator();
    }

    if (_controller.historyError != null) {
      return ErrorStateView(
        retryLabel: Translator.translate(AppStrings.retryButtonLabel),
        message: _controller.historyError!,
        onRetry: () => _controller.loadConversation(_controller.conversationId),
      );
    }

    final phase = _controller.stagePhase;
    final reply = _controller.currentReply;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        // A new exchange starts back at the top of the stage, not wherever the
        // previous (possibly long) reply was scrolled to.
        key: ValueKey('${phase.name}-${reply?.id}'),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: switch (phase) {
              MentorStagePhase.welcome => _buildWelcome(),
              MentorStagePhase.thinking => _buildThinking(),
              MentorStagePhase.talking => _buildTalking(),
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildWelcome() {
    final tokens = context.colors;
    final greeting = _displayName == null
        ? Translator.translate(AppStrings.mentorStageGreetingNoName)
        : Translator.translate(AppStrings.mentorStageGreeting, params: {'name': _displayName!});
    return [
      Text(
        greeting,
        textAlign: TextAlign.center,
        style: TextStyle(color: tokens.textPrimary, fontSize: 19, fontWeight: FontWeight.w800, height: 1.3),
      ),
      const SizedBox(height: 4),
      Text(
        Translator.translate(AppStrings.mentorStageGreetingPrompt),
        textAlign: TextAlign.center,
        style: TextStyle(color: tokens.textSecondary, fontSize: 14),
      ),
      const SizedBox(height: 14),
      MentorPetStage(petAsset: _petAsset, phase: MentorStagePhase.welcome),
      const SizedBox(height: 14),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final prompt in _controller.suggestedPrompts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SuggestedPromptChip(label: prompt, onTap: () => _send(prompt)),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildThinking() {
    final tokens = context.colors;
    return [
      MentorPetStage(petAsset: _petAsset, phase: MentorStagePhase.thinking),
      const SizedBox(height: 14),
      Text(
        Translator.translate(AppStrings.mentorStageThinkingTitle),
        textAlign: TextAlign.center,
        style: TextStyle(color: tokens.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      Text(
        Translator.translate(AppStrings.mentorStageThinkingSubtitle),
        textAlign: TextAlign.center,
        style: TextStyle(color: tokens.textTertiary, fontSize: 12),
      ),
    ];
  }

  List<Widget> _buildTalking() {
    final reply = _controller.currentReply!;
    final isRevealing = reply.id == _controller.revealingMessageId;
    return [
      MentorPetStage(petAsset: _petAsset, phase: MentorStagePhase.talking),
      const SizedBox(height: 14),
      MentorSpeechCard(
        reply: reply,
        topic: _controller.topic,
        revealingText: isRevealing ? _controller.revealingText : null,
      ),
      // The backend returns no follow-up suggestions yet, so the only
      // follow-up offered is the design's fallback: start over.
      if (!isRevealing) ...[
        const SizedBox(height: 12),
        SuggestedPromptChip(
          label: Translator.translate(AppStrings.mentorStageAskSomethingElse),
          onTap: _controller.startNewChat,
        ),
      ],
    ];
  }
}
