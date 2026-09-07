import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium/core/utils/user_scoped_prefs.dart';
import 'package:petrimonium/features/game/data/datasources/gamification_remote_datasource.dart';
import 'package:petrimonium/features/game/domain/entities/gamification_summary.dart';
import 'package:petrimonium/features/pet/data/datasources/pet_remote_datasource.dart';
import 'package:petrimonium/features/pet/data/models/pet_specie_enum.dart';
import 'package:petrimonium/features/pet/domain/entities/pet_profile.dart';
import 'package:petrimonium/features/pet/domain/enums/accessory_type.dart';
import 'package:petrimonium/features/pet/domain/enums/pet_accessory_id.dart';
import 'package:petrimonium/features/pet/domain/enums/pet_evolution_stage.dart';
import 'package:petrimonium/features/pet/domain/repositories/mascot_repository.dart';

/// [loadProfile] paints instantly from the local cache (name/stage/
/// accessories/lastActiveAt have no backend equivalent — they stay
/// local-only, not "fake"), then best-effort overwrites `xp` and `specie`
/// with the backend's real values (`GamificationRemoteDataSource`,
/// `PetRemoteDataSource`) and refreshes the cache. Offline, it falls back to
/// the last-known-real cached value — legitimate staleness, never a
/// fabricated number.
///
/// Every key is scoped to the currently logged-in account (see
/// [UserScopedPrefs]) — switching accounts on the same device must never
/// show one user's pet (name, specie, stage, XP, accessories, ...) as
/// another's. A device that already has data under the old, unscoped key
/// names is migrated onto the current account's scoped keys the first time
/// each is read, same pattern as `AchievementsLocalRepository`.
class MascotRepositoryImpl implements MascotRepository {
  MascotRepositoryImpl({
    required GamificationRemoteDataSource gamificationRemoteDataSource,
    required PetRemoteDataSource petRemoteDataSource,
  })  : _gamificationRemoteDataSource = gamificationRemoteDataSource,
        _petRemoteDataSource = petRemoteDataSource;

  final GamificationRemoteDataSource _gamificationRemoteDataSource;
  final PetRemoteDataSource _petRemoteDataSource;

  static const _nameKey = 'mascot_name';
  static const _stageKey = 'mascot_stage';
  static const _xpKey = 'mascot_xp';
  static const _specieKey = 'mascot_specie';
  static const _netWorthKey = 'mascot_net_worth';
  static const _equippedKeyPrefix = 'mascot_equipped_';
  static const _unlockedKey = 'mascot_unlocked_accessories';
  static const _lastActiveAtKey = 'mascot_last_active_at';

  @override
  Future<PetProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString(await _migrateString(prefs, _nameKey));
    final stageName = prefs.getString(await _migrateString(prefs, _stageKey));
    final stage = PetEvolutionStage.values.firstWhere(
      (s) => s.name == stageName,
      orElse: () => PetEvolutionStage.babyDog,
    );

    var xp = prefs.getInt(await _migrateInt(prefs, _xpKey)) ?? 0;
    final specieName = prefs.getString(await _migrateString(prefs, _specieKey));
    var specie = PetSpecieEnum.values.firstWhere(
      (s) => s.name == specieName,
      orElse: () => PetSpecieEnum.DOG,
    );
    final netWorth = prefs.getDouble(await _migrateDouble(prefs, _netWorthKey)) ?? 0;

    final unlockedNames = prefs.getStringList(await _migrateStringList(prefs, _unlockedKey)) ?? const [];
    final unlocked = <PetAccessoryId>{
      for (final n in unlockedNames) ..._findAccessoryById(n),
    };

    final equipped = <AccessoryType, PetAccessoryId>{};
    for (final slot in AccessoryType.values) {
      final saved = prefs.getString(await _migrateString(prefs, '$_equippedKeyPrefix${slot.name}'));
      if (saved == null) continue;
      final matches = _findAccessoryById(saved);
      if (matches.isNotEmpty) equipped[slot] = matches.first;
    }

    final lastActiveIso = prefs.getString(await _migrateString(prefs, _lastActiveAtKey));
    final lastActiveAt =
        lastActiveIso != null ? DateTime.tryParse(lastActiveIso) : null;

    try {
      final summary = await _gamificationRemoteDataSource.fetchSummary();
      xp = GamificationSummary.fromJson(summary).totalXp;
      await saveXp(xp);
    } catch (_) {
      // Offline or backend unavailable — keep the last-known-real cached XP.
    }

    try {
      final petData = await _petRemoteDataSource.getMyPet();
      final realSpecieName = petData?['specie'] as String?;
      if (realSpecieName != null) {
        specie = PetSpecieEnum.values.firstWhere(
          (s) => s.name == realSpecieName,
          orElse: () => specie,
        );
        await saveSpecie(specie);
      }
    } catch (_) {
      // Offline or backend unavailable — keep the last-known-real cached specie.
    }

    return PetProfile(
      specie: specie,
      name: name,
      stage: stage,
      xp: xp,
      netWorth: netWorth,
      unlockedAccessories: unlocked,
      equippedAccessories: equipped,
      lastActiveAt: lastActiveAt ?? DateTime.now(),
    );
  }

  @override
  Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await UserScopedPrefs.key(_nameKey), name);
  }

  @override
  Future<void> saveStage(PetEvolutionStage stage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await UserScopedPrefs.key(_stageKey), stage.name);
  }

  @override
  Future<void> saveXp(int xp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(await UserScopedPrefs.key(_xpKey), xp);
  }

  @override
  Future<void> saveSpecie(PetSpecieEnum specie) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await UserScopedPrefs.key(_specieKey), specie.name);
  }

  @override
  Future<void> saveNetWorth(double netWorth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(await UserScopedPrefs.key(_netWorthKey), netWorth);
  }

  @override
  Future<void> saveEquippedAccessories(
    Map<AccessoryType, PetAccessoryId> equipped,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    for (final slot in AccessoryType.values) {
      final key = await UserScopedPrefs.key('$_equippedKeyPrefix${slot.name}');
      final accessory = equipped[slot];
      if (accessory == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, accessory.name);
      }
    }
  }

  @override
  Future<void> saveUnlockedAccessories(Set<PetAccessoryId> unlocked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      await UserScopedPrefs.key(_unlockedKey),
      unlocked.map((a) => a.name).toList(),
    );
  }

  @override
  Future<void> saveLastActiveAt(DateTime lastActiveAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await UserScopedPrefs.key(_lastActiveAtKey), lastActiveAt.toIso8601String());
  }

  /// Returns [baseKey]'s scoped form, migrating over any value still sitting
  /// under the old unscoped key the first time it's read on this device —
  /// see `AchievementsLocalRepository._migrateStringList` for the same
  /// pattern and its rationale. One helper per `SharedPreferences` value
  /// type, since it has no generic get/set pair.
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

  Future<String> _migrateInt(SharedPreferences prefs, String baseKey) async {
    final scopedKey = await UserScopedPrefs.key(baseKey);
    if (!prefs.containsKey(scopedKey)) {
      final legacy = prefs.getInt(baseKey);
      if (legacy != null) {
        await prefs.setInt(scopedKey, legacy);
        await prefs.remove(baseKey);
      }
    }
    return scopedKey;
  }

  Future<String> _migrateDouble(SharedPreferences prefs, String baseKey) async {
    final scopedKey = await UserScopedPrefs.key(baseKey);
    if (!prefs.containsKey(scopedKey)) {
      final legacy = prefs.getDouble(baseKey);
      if (legacy != null) {
        await prefs.setDouble(scopedKey, legacy);
        await prefs.remove(baseKey);
      }
    }
    return scopedKey;
  }

  Future<String> _migrateStringList(SharedPreferences prefs, String baseKey) async {
    final scopedKey = await UserScopedPrefs.key(baseKey);
    if (!prefs.containsKey(scopedKey)) {
      final legacy = prefs.getStringList(baseKey);
      if (legacy != null) {
        await prefs.setStringList(scopedKey, legacy);
        await prefs.remove(baseKey);
      }
    }
    return scopedKey;
  }
}

Iterable<PetAccessoryId> _findAccessoryById(String name) {
  return PetAccessoryId.values.where((a) => a.name == name);
}
