import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// Shown when the student holds nothing *right now* but has traded before.
///
/// The empty-state card this replaces ("Monte sua carteira simulada — adicione
/// seu primeiro ativo") is true only for someone who has never started. Shown
/// to someone who just sold their last position, it erased what they had just
/// done; the history section below this card is where that lives now.
class SimulatedAllPositionsClosedCard extends StatelessWidget {
  const SimulatedAllPositionsClosedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 20, color: tokens.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  Translator.translate(AppStrings.simulatedAllPositionsClosedTitle),
                  style: TextStyle(color: tokens.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Translator.translate(AppStrings.simulatedAllPositionsClosedBody),
            style: TextStyle(color: tokens.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
