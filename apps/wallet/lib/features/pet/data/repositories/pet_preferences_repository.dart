import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium/core/utils/user_scoped_prefs.dart';
import 'package:petrimonium/features/pet/data/models/investment_horizon_enum.dart';
import 'package:petrimonium/features/pet/data/models/pet_goal_enum.dart';

/// Persists the user's chosen main goal / investment horizon from pet
/// profile creation. Local-only (SharedPreferences), mirroring
/// `MascotRepositoryImpl`'s style — there is no backend field for this yet
/// (the `Pet` entity only stores specie/health), so this keeps the
/// selection from being purely decorative without requiring a backend
/// schema change for a value nothing else currently consumes.
///
/// Both keys are scoped to the currently logged-in account (see
/// [UserScopedPrefs]) — switching accounts on the same device must never
/// show one user's chosen goal/horizon as another's (Demanda #57). A device
/// that already has data under the old, unscoped key names is migrated onto
/// the current account's scoped keys the first time each is read.
class PetPreferencesRepository {
  static const _goalKey = 'pet_goal';
  static const _horizonKey = 'pet_investment_horizon';

  Future<PetGoalEnum> loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return PetGoalEnumDisplay.fromName(prefs.getString(await _migrateString(prefs, _goalKey)));
  }

  Future<void> saveGoal(PetGoalEnum goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await UserScopedPrefs.key(_goalKey), goal.name);
  }

  Future<InvestmentHorizonEnum> loadHorizon() async {
    final prefs = await SharedPreferences.getInstance();
    return InvestmentHorizonEnumDisplay.fromName(prefs.getString(await _migrateString(prefs, _horizonKey)));
  }

  Future<void> saveHorizon(InvestmentHorizonEnum horizon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await UserScopedPrefs.key(_horizonKey), horizon.name);
  }

  /// Returns [baseKey]'s scoped form, migrating over any value still sitting
  /// under the old unscoped key the first time it's read on this device —
  /// see `AchievementsLocalRepository._migrateStringList` for the same
  /// pattern and its rationale.
  Future<String> _migrateString(SharedPreferences prefs, String baseKey) async {
    final scopedKey = await UserScopedPrefs.key(baseKey);
    if (!prefs.containsKey(scopedKey)) {
      final legacy = prefs.getString(baseKey);
      if (legacy != null) {
        await prefs.setString(scopedKey, legacy);
        await prefs.remove(baseKey);
      }
    }
    return scopedKey;
  }
}
