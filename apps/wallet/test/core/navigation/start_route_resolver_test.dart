import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium/core/navigation/start_route_resolver.dart';
import 'package:petrimonium/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:petrimonium/features/auth/data/repositories/auth_repository.dart';
import 'package:petrimonium/features/onboarding/data/repositories/onboarding_state_repository.dart';
import 'package:petrimonium/features/pet/data/models/pet_specie_enum.dart';
import 'package:petrimonium/features/pet/domain/entities/pet_profile.dart';
import 'package:petrimonium/features/pet/domain/enums/accessory_type.dart';
import 'package:petrimonium/features/pet/domain/enums/pet_accessory_id.dart';
import 'package:petrimonium/features/pet/domain/enums/pet_evolution_stage.dart';
import 'package:petrimonium/features/pet/domain/repositories/mascot_repository.dart';
import 'package:petrimonium/features/pet/domain/repositories/pet_repository.dart';

/// In-memory [AuthRepository] double — real `AuthRepository` reads/writes
/// `SharedPreferences` directly, which isn't available in a plain unit test.
class FakeAuthRepository implements AuthRepository {
  bool loggedIn = true;
  bool logoutCalled = false;

  @override
  Future<bool> isLoggedIn() async => loggedIn;

  @override
  Future<void> logout() async {
    logoutCalled = true;
    loggedIn = false;
  }

  @override
  Future<void> login(String email, String password) async {}

  @override
  Future<void> loginWithGoogle() async {}

  @override
  Future<void> register(String name, String email, String password) async {}

  @override
  Future<String?> getSavedEmail() async => null;

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> resetPassword(String token, String newPassword) async {}

  @override
  AuthRemoteDataSource get remoteDataSource => throw UnimplementedError();
}

class FakePetRepository implements PetRepository {
  bool hasPet = true;
  Object? statusError;
  final List<PetSpecieEnum> configuredSpecies = [];

  @override
  Future<bool> getPetStatus() async {
    if (statusError != null) throw statusError!;
    return hasPet;
  }

  @override
  Future<void> configurePet(PetSpecieEnum specie) async {
    configuredSpecies.add(specie);
    hasPet = true;
  }

  @override
  Future<Map<String, dynamic>?> getMyPet() async => null;
}

class FakeMascotRepository implements MascotRepository {
  PetProfile profileToReturn = PetProfile(name: 'Rex');
  final List<String> savedNames = [];

  @override
  Future<PetProfile> loadProfile() async => profileToReturn;

  @override
  Future<void> saveName(String name) async {
    savedNames.add(name);
    profileToReturn = PetProfile(name: name);
  }

  @override
  Future<void> saveStage(PetEvolutionStage stage) async {}

  @override
  Future<void> saveXp(int xp) async {}

  @override
  Future<void> saveSpecie(PetSpecieEnum specie) async {}

  @override
  Future<void> saveNetWorth(double netWorth) async {}

  @override
  Future<void> saveEquippedAccessories(
    Map<AccessoryType, PetAccessoryId> equipped,
  ) async {}

  @override
  Future<void> saveUnlockedAccessories(Set<PetAccessoryId> unlocked) async {}

  @override
  Future<void> saveLastActiveAt(DateTime lastActiveAt) async {}
}

/// In-memory [OnboardingStateRepository] double for the fields
/// [StartRouteResolver] actually reads.
class FakeOnboardingStateRepository implements OnboardingStateRepository {
  bool mentorWelcomeSeen = true;
  bool quickSetupDone = true;

  @override
  Future<bool> hasSeenMentorWelcome() async => mentorWelcomeSeen;

  @override
  Future<void> markMentorWelcomeSeen() async {
    mentorWelcomeSeen = true;
  }

  @override
  Future<bool> hasCompletedQuickSetup() async => quickSetupDone;

  @override
  Future<void> markQuickSetupDone() async {
    quickSetupDone = true;
  }

  @override
  Future<bool> hasSetGoal() async => true;

  @override
  Future<bool> isTutorialCompleted() async => true;

  @override
  Future<bool> isPortfolioStepDone() async => true;

  @override
  Future<void> setGoalChosen() async {}

  @override
  Future<void> completeTutorial() async {}

  @override
  Future<bool> isPortfolioConnected() async => false;

  @override
  Future<void> markPortfolioConnected() async {}

  @override
  Future<void> markPortfolioSkipped({DateTime? now}) async {}

  @override
  Future<int> incrementSessionCount() async => 0;

  @override
  Future<int> currentSessionCount() async => 0;

  @override
  Future<void> markReminderShown(int atSession) async {}

  @override
  Future<bool> shouldShowPortfolioReminder() async => false;

  @override
  Future<bool> hasSeenPortfolioActivation() async => false;

  @override
  Future<void> markPortfolioActivationSeen() async {}
}

void main() {
  late FakeAuthRepository authRepository;
  late FakePetRepository petRepository;
  late FakeMascotRepository mascotRepository;
  late FakeOnboardingStateRepository onboardingStateRepository;
  late StartRouteResolver resolver;

  setUp(() {
    authRepository = FakeAuthRepository();
    petRepository = FakePetRepository();
    mascotRepository = FakeMascotRepository();
    onboardingStateRepository = FakeOnboardingStateRepository();
    resolver = StartRouteResolver(
      authRepository: authRepository,
      petRepository: petRepository,
      mascotRepository: mascotRepository,
      onboardingStateRepository: onboardingStateRepository,
    );
  });

  test(
    'not logged in routes to login, before touching any other state',
    () async {
      authRepository.loggedIn = false;

      final route = await resolver.resolve();

      expect(route, StartRoute.login);
    },
  );

  test('logged in, mentor welcome not seen yet, routes to mentorWelcome', () async {
    onboardingStateRepository.mentorWelcomeSeen = false;

    final route = await resolver.resolve();

    expect(route, StartRoute.mentorWelcome);
  });

  test('welcome seen but quick setup not done routes to quickSetup', () async {
    onboardingStateRepository.quickSetupDone = false;

    final route = await resolver.resolve();

    expect(route, StartRoute.quickSetup);
  });

  test('everything resolved routes home', () async {
    final route = await resolver.resolve();

    expect(route, StartRoute.home);
  });

  test(
    'a Wallet-first signup with no pet routes to petSetup, without provisioning anything itself',
    () async {
      petRepository.hasPet = false;
      mascotRepository.profileToReturn = PetProfile(name: null);

      final route = await resolver.resolve();

      // PetSetupScreen — not the resolver — is responsible for calling
      // configurePet/saveName once the user actually chooses a species/name.
      expect(petRepository.configuredSpecies, isEmpty);
      expect(mascotRepository.savedNames, isEmpty);
      expect(route, StartRoute.petSetup);
    },
  );

  test(
    'an existing pet with no locally-cached name (e.g. an Academy pet on a new device) gets the default name backfilled, no petSetup shown',
    () async {
      petRepository.hasPet = true;
      mascotRepository.profileToReturn = PetProfile(name: null);

      final route = await resolver.resolve();

      expect(petRepository.configuredSpecies, isEmpty);
      expect(mascotRepository.savedNames, [kDefaultWalletPetName]);
      expect(route, isNot(StartRoute.petSetup));
    },
  );

  test('an already-named pet is left untouched — no re-provisioning', () async {
    mascotRepository.profileToReturn = PetProfile(name: 'Rex');

    await resolver.resolve();

    expect(mascotRepository.savedNames, isEmpty);
  });

  test(
    'a failure reading pet/onboarding state logs the user out and routes to login',
    () async {
      petRepository.statusError = Exception('boom');

      final route = await resolver.resolve();

      expect(route, StartRoute.login);
      expect(authRepository.logoutCalled, isTrue);
    },
  );

  /// DEM-102: getPetStatus's TimeoutException (ApiClient's 15s bound) is
  /// exactly what a device with no signal throws on cold start. Being
  /// offline must not cost the session — ApiClient's own token-refresh path
  /// (_performRefresh) already draws the same "network failure isn't proof
  /// the session is invalid" distinction.
  test(
    'a network timeout preserves the session and routes home, not login',
    () async {
      petRepository.statusError = TimeoutException('boom');

      final route = await resolver.resolve();

      expect(route, StartRoute.home);
      expect(authRepository.logoutCalled, isFalse);
      expect(authRepository.loggedIn, isTrue);
    },
  );

  test(
    'no connectivity (SocketException) preserves the session and routes home, not login',
    () async {
      petRepository.statusError = const SocketException('Failed host lookup');

      final route = await resolver.resolve();

      expect(route, StartRoute.home);
      expect(authRepository.logoutCalled, isFalse);
    },
  );
}
