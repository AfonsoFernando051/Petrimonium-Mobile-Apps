import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/translator.dart';
import '../../../../core/widgets/confirm_logout_dialog.dart';
import '../../../../core/widgets/cosmic_background.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/utils/game_snack.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../home/presentation/screens/overview_screen.dart';
import '../../../pet/presentation/mascot/controllers/mascot_controller.dart';
import '../../../portfolio/presentation/controllers/portfolio_controller.dart';
import '../../../portfolio/presentation/screens/passive_income_screen.dart';
import '../../../portfolio/presentation/widgets/dividend_notifications_sheet.dart';
import '../../../mentor/presentation/screens/mentor_screen.dart';
import '../../../pet/presentation/companion/pet_companion_controller.dart';
import '../../../pet/presentation/companion/pet_context.dart';
import '../../../pet/presentation/companion/widgets/pet_companion_header.dart';
import '../../../pet/presentation/companion/widgets/pet_speech_bubble.dart';
import '../../../pet/presentation/companion/widgets/pet_speech_bubble_anchor.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../services/dashboard_tab_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Feeds Início's patrimônio/holdings sections — a single in-flight load,
  // shared with whatever else in this screen still touches portfolio data.
  late final MascotController _mascotController;
  late final PortfolioController _portfolioController;

  // The persistent pet companion's speech-bubble/interaction state — one
  // instance shared by every tab and by `ProfileScreen` (pushed with it),
  // so there is a single message queue/cooldown ledger for the whole
  // authenticated session (see `PetCompanionController` class doc).
  late final PetCompanionController _companionController;

  // Where the Pet actually renders on screen, for `PetSpeechBubbleOverlay`
  // to glue its bubble to (see `PetSpeechBubbleAnchor`'s doc comment).
  // `_heroAnchor` is Home's big, more expressive pet (`LearningHeroCard`)
  // and takes priority whenever Home is the visible tab; `_headerAnchor` is
  // the always-present AppBar avatar every other tab falls back to.
  final PetSpeechBubbleAnchor _heroAnchor = PetSpeechBubbleAnchor();
  final PetSpeechBubbleAnchor _headerAnchor = PetSpeechBubbleAnchor();

  PetSpeechBubbleAnchor get _activeCompanionAnchor =>
      _selectedIndex == 0 ? _heroAnchor : _headerAnchor;

  // Which conversation the Mentor tab should open into — set by Home's
  // Mentor card ("Por que estou vendo isto?") to resume the exact
  // conversation its interpretation came from; `null` opens a blank chat as
  // usual. `MentorScreen` stays mounted in the IndexedStack below, so
  // `didUpdateWidget` (not `initState`) is what actually picks this up.
  int? _pendingMentorConversationId;

  @override
  void initState() {
    super.initState();
    _mascotController = MascotController(repository: DI.mascotRepository);
    _companionController = PetCompanionController(
      mascotController: _mascotController,
      preferencesRepository: DI.petCompanionPreferencesRepository,
    );
    _portfolioController = PortfolioController(
      repository: DI.portfolioRepository,
      achievementsLocalRepository: DI.achievementsLocalRepository,
      achievementsRepository: DI.achievementsRepository,
      gamificationRepository: DI.gamificationRepository,
      missionsRepository: DI.missionsRepository,
      mascotController: _mascotController,
    );
    _initCompanionGreeting();
    _portfolioController.addListener(_onPortfolioChanged);
    _portfolioController.loadAll();
    // Loaded here (not just on first Proventos-tab visit) so the
    // notification bell's badge reflects real upcoming payments as soon as
    // the dashboard opens, even if the user never taps into Proventos.
    _portfolioController.loadDividendRadarIfNeeded();
  }

  Future<void> _initCompanionGreeting() async {
    await _mascotController.loadProfile();
    if (!mounted) return;
    _companionController.enterContext(PetContext.home);
  }

  void _onPortfolioChanged() {
    setState(() {
      // The Proventos tab can disappear if the holdings that justified it
      // (ações/FIIs/fundos) get sold off mid-session — bounce back to
      // Início rather than leaving the user stranded on a tab with no nav
      // item pointing at it.
      if (_selectedIndex == DashboardTabRouter.passiveIncomeTab &&
          !_visibleTabIndices.contains(_selectedIndex)) {
        _selectedIndex = DashboardTabRouter.homeTab;
      }
    });
  }

  // ── Proventos tab visibility ─────────────────────────────────────────────
  // Only shown when the wallet actually holds an asset type that pays out
  // dividends/proventos (ações, FIIs, ETFs/fundos) — see
  // `InvestmentTypePayout.paysDividends` and
  // `PortfolioController.hasDividendPayingHoldings`.
  List<int> get _visibleTabIndices => [
    DashboardTabRouter.homeTab,
    if (_portfolioController.hasDividendPayingHoldings)
      DashboardTabRouter.passiveIncomeTab,
    DashboardTabRouter.mentorTab,
  ];

  @override
  void dispose() {
    _portfolioController.removeListener(_onPortfolioChanged);
    _portfolioController.dispose();
    _companionController.dispose();
    _mascotController.dispose();
    super.dispose();
  }

  // Shared background instance for all tabs (the IndexedStack below keeps
  // every tab's state alive, so there's one CosmicBackground behind all of
  // them, not five).
  Widget _buildBackground({required Widget child}) {
    return CosmicBackground(child: child);
  }

  // ── Page route helper ─────────────────────────────────────────────────────
  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
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

  // ── Persistent pet companion: route-aware context + destination routing ──
  void _onTabSelected(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    _companionController.enterContext(
      DashboardTabRouter.petContextFor(index),
      data: DashboardTabRouter.showsHoldingsCount(index)
          ? {'count': '${_portfolioController.holdings.length}'}
          : const {},
    );
  }

  /// Where "Learn" / "Portfolio" / "Progress" in [PetInteractionSheet], or a
  /// speech-bubble action, actually take the user.
  void _handleCompanionDestination(PetContext destination) {
    switch (destination) {
      case PetContext.academy:
        // Wallet has no in-app Academy tab — Academy is a separate app.
        _showAcademyComingSoon();
      case PetContext.portfolio:
        _onTabSelected(DashboardTabRouter.homeTab);
      case PetContext.mentor:
        _onTabSelected(DashboardTabRouter.mentorTab);
      case PetContext.home:
        _onTabSelected(DashboardTabRouter.homeTab);
      case PetContext.profile:
        _openProfile();
    }
  }

  // Wallet has no in-app Academy tab or shared code with the Academy app —
  // a graceful placeholder rather than a broken/no-op tap target, until real
  // OS-level deep-linking exists.
  void _showAcademyComingSoon() {
    GameSnack.show(
      context,
      Translator.translate(AppStrings.academyBridgeComingSoon),
    );
  }

  Future<void> _openProfile() async {
    _companionController.dismiss();
    _companionController.enterContext(PetContext.profile);
    await Navigator.of(context).push(
      _fadeRoute(ProfileScreen(companionController: _companionController)),
    );
    // Settings (reached via Profile) may have renamed the pet —
    // reload so the AppBar/greeting reflect it immediately.
    await _mascotController.loadProfile();
    if (mounted) setState(() {});
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _confirmLogout() async {
    final confirmed = await ConfirmLogoutDialog.show(context);

    if (confirmed && mounted) {
      HapticFeedback.mediumImpact();
      await DI.authRepository.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(_fadeRoute(const LoginScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds the AppBar/bottom-nav chrome (and everything under it) when
    // the user switches language in Settings — matches the same explicit
    // per-screen listening pattern `SettingsScreen` and the Academy screens
    // already use, rather than relying on the top-level `MyApp` rebuild
    // alone (which resets `FutureBuilder`'s start-route resolution and would
    // otherwise flash the splash screen on every language switch).
    return ValueListenableBuilder<String>(
      valueListenable: Translator.languageNotifier,
      builder: (context, _, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final tokens = context.colors;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: _buildAppBarTitle(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _buildNotificationsButton(),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: tokens.textSecondary),
            tooltip: Translator.translate(AppStrings.profileTooltip),
            onPressed: _openProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.neonPurple),
            tooltip: Translator.translate(AppStrings.logoutTooltip),
            onPressed: _confirmLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          _buildBackground(
            child: SafeArea(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHomeContent(),
                  _buildPassiveIncomeContent(),
                  _buildMentorContent(),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: PetSpeechBubbleOverlay(
              controller: _companionController,
              anchor: _activeCompanionAnchor,
              onActionSelected: (action) =>
                  _handleCompanionDestination(action.destination),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── AppBar title — Wallet brand mark (mascot + "PETRIMONIUM WALLET", same
  // as the login screen), anchored by the persistent pet companion
  // (`docs/PROJECT_CONTEXT.md`'s Pet Companion section). No level/XP HUD
  // here — that framing belongs to the Academy, not a real-money app.
  Widget _buildAppBarTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PetCompanionHeader(
          controller: _companionController,
          onDestinationSelected: _handleCompanionDestination,
          anchor: _headerAnchor,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            Translator.translate(AppStrings.brandTitle).toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── Notifications: upcoming dividends for the user's real holdings ──────
  // Badge count is real and provider-confirmed (`DividendRadar.upcoming`,
  // the same data `DividendRadarSection` renders on the Proventos tab) —
  // never a placeholder or simulated count.
  Widget _buildNotificationsButton() {
    final upcomingCount = _portfolioController.dividendRadar.upcoming.length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: context.colors.textSecondary,
          ),
          tooltip: Translator.translate(AppStrings.notificationsTooltip),
          onPressed: _openNotifications,
        ),
        if (upcomingCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: IgnorePointer(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: context.colors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colors.backgroundSecondary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // A compact anchored popover under the bell, not a full-width bottom
  // sheet — matches the Wallet design system's denser, less decorative
  // chrome. `showGeneralDialog` + top-right `Align` approximates a real
  // anchored popover without needing the bell's exact on-screen `RenderBox`.
  void _openNotifications() {
    HapticFeedback.selectionClick();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 56, right: 8),
              child: AnimatedBuilder(
                animation: _portfolioController,
                builder: (context, _) => DividendNotificationsSheet(
                  isLoading: _portfolioController.isDividendRadarLoading,
                  error: _portfolioController.dividendRadarError,
                  upcoming: _portfolioController.dividendRadar.upcoming,
                  onRetry: _portfolioController.refreshDividendRadar,
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }

  // ── Início: unified patrimônio + Mentor dashboard, absorbing what used to
  // be a separate Carteira tab (see `DashboardTabRouter`'s class doc). ─────
  Widget _buildHomeContent() {
    return OverviewScreen(
      controller: _portfolioController,
      onOpenMentor: _openMentorFromHome,
    );
  }

  void _openMentorFromHome(int? conversationId) {
    setState(() {
      _pendingMentorConversationId = conversationId;
      _selectedIndex = DashboardTabRouter.mentorTab;
    });
  }

  // ── Proventos / Passive Income ────────────────────────────────────────────
  Widget _buildPassiveIncomeContent() {
    return PassiveIncomeScreen(controller: _portfolioController);
  }

  // ── Mentor: AI-powered chat with the pet acting as investment mentor ────
  Widget _buildMentorContent() {
    return MentorScreen(initialConversationId: _pendingMentorConversationId);
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  // Item content per logical tab (see `DashboardTabRouter`'s tab-index
  // constants) — kept separate from `_visibleTabIndices` so hiding/showing
  // Proventos doesn't duplicate icon/label definitions.
  BottomNavigationBarItem _navItemFor(int tabIndex) {
    return switch (tabIndex) {
      DashboardTabRouter.homeTab => BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: const Icon(Icons.home),
        label: Translator.translate(AppStrings.navHome),
      ),
      DashboardTabRouter.passiveIncomeTab => BottomNavigationBarItem(
        icon: const Icon(Icons.payments_outlined),
        activeIcon: const Icon(Icons.payments),
        label: Translator.translate(AppStrings.navPassiveIncome),
      ),
      _ => BottomNavigationBarItem(
        icon: const Icon(Icons.auto_awesome_outlined),
        activeIcon: const Icon(Icons.auto_awesome),
        label: Translator.translate(AppStrings.navMentor),
      ),
    };
  }

  Widget _buildBottomNav() {
    final tokens = context.colors;
    final visible = _visibleTabIndices;
    // _selectedIndex is a logical tab id (`DashboardTabRouter`'s constants),
    // not a position in the (possibly shorter) visible list — translate it
    // so BottomNavigationBar's currentIndex/onTap stay in range even while
    // Proventos is hidden.
    final currentPosition = visible.indexOf(_selectedIndex);
    return Container(
      decoration: BoxDecoration(
        color: tokens.backgroundSecondary,
        border: Border(
          top: BorderSide(
            color: tokens.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.primary.withValues(
              alpha: context.isDarkMode ? 0.12 : 0.08,
            ),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: tokens.primary,
        unselectedItemColor: tokens.textTertiary,
        selectedLabelStyle: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.caption,
        currentIndex: currentPosition == -1 ? 0 : currentPosition,
        onTap: (position) => _onTabSelected(visible[position]),
        items: [for (final tabIndex in visible) _navItemFor(tabIndex)],
      ),
    );
  }
}
