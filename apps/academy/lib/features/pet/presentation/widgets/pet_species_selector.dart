import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/constants/app_colors.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/utils/pet_assets.dart';
import 'package:petrimonium_academy/features/pet/data/models/pet_specie_enum.dart';

/// Seletor de espécie do onboarding, conforme o artboard `PetAcademy` do
/// canvas de design: grelha de 4 colunas, as 7 espécies na ordem do design
/// (raposa, cachorro, gato, coruja, lobo, urso, leão) e a arte assente direta
/// sobre o cartão — sem recorte circular, que cortava o mascote.
///
/// Construído com `Column`/`Row` e não com `GridView`: o ramo de layout largo
/// do `PetConfigurationScreen` embrulha este widget num `IntrinsicHeight`, e
/// um `GridView` baseado em slivers não sabe responder a dimensões
/// intrínsecas ("does not support returning intrinsic dimensions"); `Row` e
/// `Column` sabem.
///
/// A ordem vem de [PetSpecieEnumExtension.displayOrder] e não de
/// `PetSpecieEnum.values`: esta última segue o wire format do backend e não
/// pode ser reordenada sem quebrar a serialização.
class PetSpeciesSelector extends StatelessWidget {
  const PetSpeciesSelector({super.key, required this.selected, required this.onSelected});

  static const int _columns = 4;
  static const double _gap = 8;

  final PetSpecieEnum selected;
  final ValueChanged<PetSpecieEnum> onSelected;

  @override
  Widget build(BuildContext context) {
    const species = PetSpecieEnumExtension.displayOrder;
    final rows = <Widget>[];
    for (var start = 0; start < species.length; start += _columns) {
      final isLastRow = start + _columns >= species.length;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: isLastRow ? 0 : _gap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < _columns; column++) ...[
                if (column > 0) const SizedBox(width: _gap),
                Expanded(
                  child: start + column < species.length
                      ? _SpeciesCard(
                          specie: species[start + column],
                          isSelected: selected == species[start + column],
                          onTap: () => onSelected(species[start + column]),
                        )
                      // A última linha fica incompleta (7 não é múltiplo de 4);
                      // os lugares vazios mantêm a largura das colunas para as
                      // espécies não esticarem.
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

class _SpeciesCard extends StatelessWidget {
  const _SpeciesCard({required this.specie, required this.isSelected, required this.onTap});

  final PetSpecieEnum specie;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          // Não-selecionado é totalmente transparente (o artboard usa
          // `transparent` no contorno e no fundo), para a grelha não virar
          // uma grade de caixas.
          color: isSelected ? tokens.textPrimary.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.neonCyan : Colors.transparent, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              PetAssets.imageFor(specie.name),
              height: 46,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.pets, size: 32, color: tokens.textSecondary);
              },
            ),
            const SizedBox(height: 4),
            Text(
              specie.displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: tokens.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
