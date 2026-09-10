import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/pet/data/models/pet_specie_enum.dart';
import 'package:petrimonium_academy/features/pet/presentation/widgets/pet_species_selector.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget buildTestableWidget({PetSpecieEnum selected = PetSpecieEnum.WOLF, ValueChanged<PetSpecieEnum>? onSelected}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: PetSpeciesSelector(selected: selected, onSelected: onSelected ?? (_) {}),
      ),
    );
  }

  group('PetSpeciesSelector', () {
    testWidgets('renders every species with its translated label, never the wire format', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      for (final specie in PetSpecieEnum.values) {
        expect(find.text(specie.displayLabel), findsOneWidget, reason: specie.name);
        // "DOG"/"Dog" chegar ao ecrã significa que o rótulo caiu para o
        // formato de transporte do backend — foi esse o defeito corrigido.
        final capitalized = specie.name[0] + specie.name.substring(1).toLowerCase();
        expect(find.text(capitalized), findsNothing, reason: specie.name);
      }
    });

    testWidgets('shows the seven species in the design canvas order', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Ordem do artboard `PetAcademy`, que não é a ordem do enum (wire format).
      const expected = [
        PetSpecieEnum.FOX,
        PetSpecieEnum.DOG,
        PetSpecieEnum.CAT,
        PetSpecieEnum.OWL,
        PetSpecieEnum.WOLF,
        PetSpecieEnum.BEAR,
        PetSpecieEnum.LION,
      ];
      expect(PetSpecieEnumExtension.displayOrder, expected);
      expect(
        PetSpecieEnumExtension.displayOrder.toSet(),
        PetSpecieEnum.values.toSet(),
        reason: 'nenhuma espécie pode ficar de fora do seletor',
      );

      final positions = [for (final s in expected) tester.getTopLeft(find.text(s.displayLabel))];
      for (var i = 1; i < positions.length; i++) {
        final previous = positions[i - 1];
        final current = positions[i];
        final laterInReadingOrder = current.dy > previous.dy || (current.dy == previous.dy && current.dx > previous.dx);
        expect(laterInReadingOrder, isTrue, reason: '${expected[i].name} veio antes de ${expected[i - 1].name}');
      }
    });

    testWidgets('renders the art uncropped — no circular clip', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // A arte vem com fundo transparente; o ClipOval que aqui existia cortava
      // o mascote, ao contrário do que o canvas mostra.
      expect(find.byType(ClipOval), findsNothing);

      final image = tester.widget<Image>(find.byType(Image).first);
      expect(image.height, 46);
      expect(image.fit, BoxFit.contain);
    });

    testWidgets('tapping a species invokes onSelected with that species', (tester) async {
      PetSpecieEnum? selected;
      await tester.pumpWidget(buildTestableWidget(onSelected: (s) => selected = s));

      await tester.tap(find.text(PetSpecieEnum.CAT.displayLabel));
      await tester.pump();

      expect(selected, PetSpecieEnum.CAT);
    });

    testWidgets('the currently selected species is visually distinguished', (tester) async {
      await tester.pumpWidget(buildTestableWidget(selected: PetSpecieEnum.WOLF));

      final wolfLabel = tester.widget<Text>(find.text(PetSpecieEnum.WOLF.displayLabel));
      final dogLabel = tester.widget<Text>(find.text(PetSpecieEnum.DOG.displayLabel));

      expect(wolfLabel.style?.fontWeight, FontWeight.w700);
      expect(dogLabel.style?.fontWeight, FontWeight.w400);
    });
  });
}
