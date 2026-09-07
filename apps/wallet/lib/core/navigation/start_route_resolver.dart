import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/features/auth/data/repositories/auth_repository.dart';
import 'package:petrimonium/features/onboarding/data/repositories/onboarding_state_repository.dart';
import 'package:petrimonium/features/pet/domain/repositories/mascot_repository.dart';
import 'package:petrimonium/features/pet/domain/repositories/pet_repository.dart';

/// Where `MyApp` should route the user on cold start.
enum StartRoute { login, petSetup, mentorWelcome, quickSetup, home }

/// A pet that already exists server-side (e.g. from the Academy) but has no
/// name cached on this device yet — first login on a new device — falls
/// back to this name rather than being sent to [StartRoute.petSetup] (see
/// [StartRouteResolver._ensureLocalPetName]): one of the same suggestions
/// `PetNameField` offers during Academy's pet-naming step, so it never reads
/// as an obviously-synthetic placeholder if the user later sees it.
const String kDefaultWalletPetName = 'Nino';

/// Resolves [StartRoute] from persisted auth/onboarding state — extracted
/// from `MyApp._getStartRoute()` so the routing rules are testable without
/// `WidgetTester`.
///
/// Each step gates the next one:
/// not authenticated -> [StartRoute.login]
/// authenticated, no Pet on the account yet -> [StartRoute.petSetup]
/// has a Pet, mentor welcome not seen yet -> [StartRoute.mentorWelcome]
/// welcome seen, quick setup (market/currency) not done -> [StartRoute.quickSetup]
/// everything resolved -> [StartRoute.home]
///
/// A returning Academy user already has a Pet ("mesma conta Petrimonium da
/// Academy") and skips [StartRoute.petSetup] entirely — the pet is a shared
/// cross-app companion, so an existing one is never re-configured, only a
/// missing local name gets backfilled (see [_ensureLocalPetName]). A
/// Wallet-first signup with no Pet at all is routed to [StartRoute.petSetup]
/// to choose a species and name it, via `PetSetupScreen`. The old
/// pet-naming/financial-goal/tutorial/portfolio-choice steps (and their
/// screens) are unreachable from cold start now but not deleted — same
/// "deferred cleanup" pattern as the rest of the Wallet/Academy split —
/// until it's decided whether any of them resurface elsewhere (e.g. a
/// "change goal" Profile setting).
class StartRouteResolver {
  StartRouteResolver({
    AuthRepository? authRepository,
    PetRepository? petRepository,
    MascotRepository? mascotRepository,
    OnboardingStateRepository? onboardingStateRepository,
  })  : _authRepository = authRepository ?? DI.authRepository,
        _petRepository = petRepository ?? DI.petRepository,
        _mascotRepository = mascotRepository ?? DI.mascotRepository,
        _onboardingStateRepository = onboardingStateRepository ?? DI.onboardingStateRepository;

  final AuthRepository _authRepository;
  final PetRepository _petRepository;
  final MascotRepository _mascotRepository;
  final OnboardingStateRepository _onboardingStateRepository;

  Future<StartRoute> resolve() async {
    final loggedIn = await _authRepository.isLoggedIn();
    if (!loggedIn) return StartRoute.login;

    try {
      final hasPet = await _petRepository.getPetStatus();
      if (!hasPet) return StartRoute.petSetup;

      await _ensureLocalPetName();

      final seenMentorWelcome = await _onboardingStateRepository.hasSeenMentorWelcome();
      if (!seenMentorWelcome) return StartRoute.mentorWelcome;

      final quickSetupDone = await _onboardingStateRepository.hasCompletedQuickSetup();
      if (!quickSetupDone) return StartRoute.quickSetup;

      return StartRoute.home;
    } catch (error) {
      // A network-level failure here (no connectivity, backend unreachable,
      // 15s timeout) is not the same claim as "this session is invalid" —
      // ApiClient's own token-refresh path draws the same distinction (see
      // its _performRefresh doc comment). Opening the app with no signal
      // must not cost the session: fall through to home rather than log
      // out. This resolver only decides which screen to show first — it
      // isn't the only place pet/onboarding state gets loaded, so a still-
      // offline device lands on Home with whatever partial/stale state its
      // own widgets already handle, instead of a guaranteed empty login
      // form.
      //
      // Anything else reaching here (in practice: a real non-200 from
      // getPetStatus, e.g. a JWT whose signature still checks out locally
      // but whose user no longer exists server-side) is a genuine "not
      // safely resumable" state — log out rather than risk stranding the
      // user on a screen that assumes state that couldn't be loaded.
      if (_isNetworkFailure(error)) {
        return StartRoute.home;
      }
      await _authRepository.logout();
      return StartRoute.login;
    }
  }

  bool _isNetworkFailure(Object error) {
    return error is TimeoutException || error is SocketException || error is http.ClientException;
  }

  Future<void> _ensureLocalPetName() async {
    final profile = await _mascotRepository.loadProfile();
    final hasName = profile.name != null && profile.name!.trim().isNotEmpty;
    if (!hasName) {
      await _mascotRepository.saveName(kDefaultWalletPetName);
    }
  }
}
