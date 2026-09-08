import 'package:flutter/material.dart';
import 'package:petrimonium_academy/features/pet/data/models/pet_specie_enum.dart';
import 'package:petrimonium_academy/features/pet/domain/entities/pet_profile.dart';
import 'package:petrimonium_academy/features/pet/domain/enums/accessory_type.dart';
import 'package:petrimonium_academy/features/pet/domain/enums/pet_accessory_id.dart';
import 'package:petrimonium_academy/features/pet/domain/enums/pet_animation_state.dart';
import 'package:petrimonium_academy/features/pet/domain/enums/pet_evolution_stage.dart';
import 'package:petrimonium_academy/features/pet/domain/repositories/mascot_repository.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/widgets/pet_mascot_widget.dart';

/// Development-only tool for manually exercising every [PetAnimationState]
/// and checking transitions, interruption and sizing without needing to
/// reach the real trigger (finish a lesson, wait for inactivity, etc.) in
/// the running app.
///
/// **Not part of the production app.** [main.dart] never imports this file,
/// so there is no code path — debug build or otherwise — that reaches it
/// from the shipped app. Launch it directly as its own entrypoint instead:
///
/// ```
/// flutter run -t lib/dev/main_pet_playground.dart
/// ```
class PetAnimationPlaygroundScreen extends StatefulWidget {
  const PetAnimationPlaygroundScreen({super.key});

  @override
  State<PetAnimationPlaygroundScreen> createState() => _PetAnimationPlaygroundScreenState();
}

class _PetAnimationPlaygroundScreenState extends State<PetAnimationPlaygroundScreen> {
  late final MascotController _controller;
  double _size = 220;
  bool _attentive = false;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = MascotController(repository: _InMemoryMascotRepository());
    _controller.loadProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(PetAnimationState state) {
    // A generous duration: this screen is for looking at a pose, not for
    // timing how long it naturally lasts in the app.
    _controller.triggerEventAnimation(state, duration: const Duration(minutes: 10));
  }

  Future<void> _rapidFire() async {
    for (final state in PetAnimationState.values) {
      _set(state);
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    _set(PetAnimationState.idle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pet Animation Playground')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.black12,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(disableAnimations: _reducedMotion),
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => SingleChildScrollView(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PetMascotWidget(
                                controller: _controller,
                                size: _size,
                                attentive: _attentive,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'state: ${_controller.animationState.name}'
                                '${_attentive ? ' (attentive → listening)' : ''}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('States', style: Theme.of(context).textTheme.titleMedium),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final state in PetAnimationState.values)
                          ElevatedButton(
                            onPressed: () => _set(state),
                            child: Text(state.name),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _rapidFire,
                      child: const Text('Rapid-fire every state (stress test)'),
                    ),
                    const Divider(height: 32),
                    Text('Size: ${_size.round()}px', style: Theme.of(context).textTheme.titleMedium),
                    Slider(
                      min: 24,
                      max: 220,
                      value: _size,
                      label: '${_size.round()}px',
                      onChanged: (value) => setState(() => _size = value),
                    ),
                    Text(
                      'Matches real embeddings: 28 (inline feedback), 40 (header/sheet/mentor '
                      'card), 64 (lesson complete), 220 (default/showcase).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Divider(height: 32),
                    SwitchListTile(
                      title: const Text('attentive (interaction sheet open)'),
                      value: _attentive,
                      onChanged: (value) => setState(() => _attentive = value),
                    ),
                    SwitchListTile(
                      title: const Text('reducedMotion (MediaQuery.disableAnimations)'),
                      value: _reducedMotion,
                      onChanged: (value) => setState(() => _reducedMotion = value),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Never persists anything — the playground only needs a plausible,
/// stable [PetProfile] to render against.
class _InMemoryMascotRepository implements MascotRepository {
  @override
  Future<PetProfile> loadProfile() async => PetProfile(specie: PetSpecieEnum.DOG);
  @override
  Future<void> saveName(String name) async {}
  @override
  Future<void> saveStage(PetEvolutionStage stage) async {}
  @override
  Future<void> saveXp(int xp) async {}
  @override
  Future<void> saveSpecie(PetSpecieEnum specie) async {}
  @override
  Future<void> saveNetWorth(double netWorth) async {}
  @override
  Future<void> saveEquippedAccessories(Map<AccessoryType, PetAccessoryId> equipped) async {}
  @override
  Future<void> saveUnlockedAccessories(Set<PetAccessoryId> unlocked) async {}
  @override
  Future<void> saveLastActiveAt(DateTime lastActiveAt) async {}
}
