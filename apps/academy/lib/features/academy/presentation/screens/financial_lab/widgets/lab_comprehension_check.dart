import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/features/academy/presentation/widgets/steps/choice_question_step_view.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';

/// A simulator's "what did you learn?" moment — a thin stateful wrapper
/// around the existing, already-built `ChoiceQuestionStepView` (the same
/// widget Academy lessons use for in-lesson questions) rather than a new
/// question UI. Unlimited free retries, no penalty — matches the Academy's
/// no-punishment convention (`docs/DECISIONS.md` DECISION-037).
class LabComprehensionCheck extends StatefulWidget {
  const LabComprehensionCheck({
    super.key,
    required this.step,
    required this.mascotController,
    required this.onAnsweredCorrectly,
  });

  final ChoiceQuestionStep step;
  final MascotController mascotController;

  /// Fired exactly once, the moment the correct option is first picked.
  final VoidCallback onAnsweredCorrectly;

  @override
  State<LabComprehensionCheck> createState() => _LabComprehensionCheckState();
}

class _LabComprehensionCheckState extends State<LabComprehensionCheck> {
  int? _selectedIndex;
  bool _hasAnswered = false;
  bool _answeredCorrectly = false;
  bool _firedCallback = false;

  void _onSelect(int index) {
    if (_answeredCorrectly) return;
    final correct = index == widget.step.correctIndex;
    setState(() {
      _selectedIndex = index;
      _hasAnswered = true;
      _answeredCorrectly = correct;
    });
    if (correct && !_firedCallback) {
      _firedCallback = true;
      widget.onAnsweredCorrectly();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: AppRadii.xl,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ChoiceQuestionStepView(
          step: widget.step,
          stepIndex: 0,
          selectedIndex: _selectedIndex,
          hasAnswered: _hasAnswered,
          answeredCorrectly: _answeredCorrectly,
          onSelect: _onSelect,
          mascotController: widget.mascotController,
        ),
      ),
    );
  }
}
