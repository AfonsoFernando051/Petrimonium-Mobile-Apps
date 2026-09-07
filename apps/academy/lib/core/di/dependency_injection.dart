import 'package:petrimonium_academy/core/events/app_event.dart';
import 'package:petrimonium_academy/core/events/app_event_bus.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_academy/features/academy/data/datasources/academy_remote_datasource.dart';
import 'package:petrimonium_academy/features/academy/data/datasources/lab_remote_datasource.dart';
import 'package:petrimonium_academy/features/academy/data/repositories/academy_catalog_repository.dart';
import 'package:petrimonium_academy/features/academy/data/repositories/academy_progress_local_repository.dart';
import 'package:petrimonium_academy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:petrimonium_academy/features/auth/data/repositories/auth_repository.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:petrimonium_academy/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:petrimonium_academy/features/onboarding/data/repositories/onboarding_state_repository.dart';
import 'package:petrimonium_academy/features/pet/data/datasources/pet_remote_datasource.dart';
import 'package:petrimonium_academy/features/pet/data/repositories/pet_repository_impl.dart';
import 'package:petrimonium_academy/features/pet/domain/repositories/pet_repository.dart';
import 'package:petrimonium_academy/features/pet/data/repositories/mascot_repository_impl.dart';
import 'package:petrimonium_academy/features/pet/data/repositories/pet_companion_preferences_repository.dart';
import 'package:petrimonium_academy/features/pet/data/repositories/pet_preferences_repository.dart';
import 'package:petrimonium_academy/features/pet/domain/repositories/mascot_repository.dart';
import 'package:petrimonium_academy/features/mentor/data/datasources/mentor_remote_datasource.dart';
import 'package:petrimonium_academy/features/mentor/data/repositories/mentor_chat_repository.dart';
import 'package:petrimonium_academy/features/portfolio/data/datasources/achievements_remote_datasource.dart';
import 'package:petrimonium_academy/features/portfolio/data/datasources/missions_remote_datasource.dart';
import 'package:petrimonium_academy/features/portfolio/data/datasources/portfolio_remote_datasource.dart';
import 'package:petrimonium_academy/features/portfolio/data/repositories/achievements_local_repository.dart';
import 'package:petrimonium_academy/features/portfolio/data/repositories/achievements_repository.dart';
import 'package:petrimonium_academy/features/portfolio/data/repositories/missions_repository.dart';
import 'package:petrimonium_academy/features/portfolio/data/repositories/portfolio_repository.dart';
import 'package:petrimonium_academy/features/simulated_wallet/data/datasources/simulated_wallet_remote_datasource.dart';
import 'package:petrimonium_academy/features/simulated_wallet/data/repositories/simulated_wallet_repository.dart';
import 'package:petrimonium_academy/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:petrimonium_academy/features/settings/data/repositories/settings_repository.dart';

class DI {
  // The shared ApiClient cannot emit an AppEvent itself: AppEvent is a sealed
  // hierarchy owned by this app, and a sealed type cannot be extended from
  // another library. So the bridge from "the session is definitively gone" to
  // "the app event bus" is wired here, once, at the composition root.
  /// Bridges the shared [ApiClient]'s "this session is definitively gone"
  /// signal onto this app's own event bus.
  ///
  /// Named (rather than an inline closure) so it is directly testable: the
  /// callback is optional on [ApiClient], which means forgetting to wire it
  /// would silently disable the logout-on-expiry behaviour without failing
  /// analysis or any client test.
  static void notifySessionExpired() =>
      AppEventBus.instance.emit(const SessionExpiredEvent());

  static final ApiClient _apiClient = ApiClient(
    onSessionExpired: notifySessionExpired,
  );

  static final AuthRemoteDataSource _authRemoteDataSource =
      AuthRemoteDataSource(apiClient: _apiClient);
  // Not `final` so tests can replace it with a mock repository.
  static AuthRepository authRepository = AuthRepository(
    remoteDataSource: _authRemoteDataSource,
  );

  static final OnboardingRemoteDataSource _onboardingRemoteDataSource =
      OnboardingRemoteDataSource(apiClient: _apiClient);
  // Not `final` so tests can replace it with a mock repository.
  static OnboardingRepository onboardingRepository = OnboardingRepository(
    remoteDataSource: _onboardingRemoteDataSource,
  );

  // Not `final` so tests can replace it with a mock repository.
  static OnboardingStateRepository onboardingStateRepository =
      OnboardingStateRepository();

  static final PetRemoteDataSource _petRemoteDataSource = PetRemoteDataSource(
    apiClient: _apiClient,
  );
  // Not `final` so tests can replace it with a mock repository.
  static PetRepository petRepository = PetRepositoryImpl(
    remoteDataSource: _petRemoteDataSource,
  );

  static final GamificationRemoteDataSource _gamificationRemoteDataSource =
      GamificationRemoteDataSource(apiClient: _apiClient);
  // Not `final` so tests can replace it with a mock repository.
  static GamificationRepository gamificationRepository = GamificationRepository(
    remoteDataSource: _gamificationRemoteDataSource,
  );

  // Not `final` so tests can replace it with a mock repository.
  static MascotRepository mascotRepository = MascotRepositoryImpl(
    gamificationRemoteDataSource: _gamificationRemoteDataSource,
    petRemoteDataSource: _petRemoteDataSource,
  );

  // Not `final` so tests can replace it with a mock repository.
  static PetPreferencesRepository petPreferencesRepository =
      PetPreferencesRepository();

  // Not `final` so tests can replace it with a mock repository.
  static PetCompanionPreferencesRepository petCompanionPreferencesRepository =
      PetCompanionPreferencesRepository();

  static final SettingsRemoteDataSource _settingsRemoteDataSource =
      SettingsRemoteDataSource(apiClient: _apiClient);
  // Not `final` so tests can replace it with a mock repository.
  static SettingsRepository settingsRepository = SettingsRepository(
    remoteDataSource: _settingsRemoteDataSource,
  );

  static final PortfolioRemoteDataSource _portfolioRemoteDataSource =
      PortfolioRemoteDataSource(apiClient: _apiClient);
  // Not `final` so tests can replace it with a mock repository.
  static PortfolioRepository portfolioRepository = PortfolioRepository(
    remoteDataSource: _portfolioRemoteDataSource,
  );

  static final SimulatedWalletRemoteDataSource _simulatedWalletRemoteDataSource =
      SimulatedWalletRemoteDataSource(apiClient: _apiClient);
  // Not `final` so tests can replace it with a mock repository.
  static SimulatedWalletRepository simulatedWalletRepository = SimulatedWalletRepository(
    remoteDataSource: _simulatedWalletRemoteDataSource,
  );

  // Not `final` so tests can replace it with a mock repository.
  static AchievementsLocalRepository achievementsLocalRepository =
      AchievementsLocalRepository();

  static final AchievementsRemoteDataSource _achievementsRemoteDataSource =
      AchievementsRemoteDataSource(apiClient: _apiClient);
  // Not `final` so tests can replace it with a mock repository.
  static AchievementsRepository achievementsRepository = AchievementsRepository(
    remoteDataSource: _achievementsRemoteDataSource,
  );

  static final MissionsRemoteDataSource _missionsRemoteDataSource =
      MissionsRemoteDataSource(apiClient: _apiClient);
  // Not `final` so tests can replace it with a mock repository.
  static MissionsRepository missionsRepository = MissionsRepository(
    remoteDataSource: _missionsRemoteDataSource,
  );

  // Not `final` so tests can replace it with a mock repository.
  static AcademyProgressLocalRepository academyProgressRepository =
      AcademyProgressLocalRepository();

  // Not `final` so tests can replace it with a mock datasource.
  static AcademyRemoteDataSource academyRemoteDataSource =
      AcademyRemoteDataSource(apiClient: _apiClient);

  // Not `final` so tests can replace it with a mock datasource.
  static LabRemoteDataSource labRemoteDataSource =
      LabRemoteDataSource(apiClient: _apiClient);

  // Not `final` so tests can replace it with a mock repository.
  static AcademyCatalogRepository academyCatalogRepository =
      AcademyCatalogRepository(apiClient: _apiClient);

  static final MentorRemoteDataSource _mentorRemoteDataSource =
      MentorRemoteDataSource(apiClient: _apiClient);
  // Not `final` so tests can replace it with a mock repository.
  static MentorChatRepository mentorChatRepository = MentorChatRepository(
    remoteDataSource: _mentorRemoteDataSource,
    petPreferencesRepository: petPreferencesRepository,
  );
}
