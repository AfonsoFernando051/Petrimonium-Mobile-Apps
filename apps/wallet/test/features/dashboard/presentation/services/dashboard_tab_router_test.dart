import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium/features/dashboard/presentation/services/dashboard_tab_router.dart';
import 'package:petrimonium/features/pet/presentation/companion/pet_context.dart';

void main() {
  group('DashboardTabRouter.petContextFor', () {
    test('Home tab maps to PetContext.home', () {
      expect(DashboardTabRouter.petContextFor(DashboardTabRouter.homeTab), PetContext.home);
    });

    test('Passive Income tab maps to PetContext.portfolio', () {
      expect(DashboardTabRouter.petContextFor(DashboardTabRouter.passiveIncomeTab), PetContext.portfolio);
    });

    test('Mentor tab (and any other index) maps to PetContext.mentor', () {
      expect(DashboardTabRouter.petContextFor(DashboardTabRouter.mentorTab), PetContext.mentor);
    });

    test('never maps any tab index to PetContext.academy — Wallet has no Academy tab', () {
      for (final tab in [
        DashboardTabRouter.homeTab,
        DashboardTabRouter.passiveIncomeTab,
        DashboardTabRouter.mentorTab,
      ]) {
        expect(DashboardTabRouter.petContextFor(tab), isNot(PetContext.academy));
      }
    });
  });

  group('DashboardTabRouter.showsHoldingsCount', () {
    test('true for Home/Passive Income, false for Mentor', () {
      expect(DashboardTabRouter.showsHoldingsCount(DashboardTabRouter.homeTab), isTrue);
      expect(DashboardTabRouter.showsHoldingsCount(DashboardTabRouter.passiveIncomeTab), isTrue);
      expect(DashboardTabRouter.showsHoldingsCount(DashboardTabRouter.mentorTab), isFalse);
    });
  });
}
