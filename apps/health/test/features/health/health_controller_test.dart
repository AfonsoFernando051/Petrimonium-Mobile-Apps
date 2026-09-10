import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium_health/core/i18n/locale_controller.dart';
import 'package:petrimonium_health/core/money/money.dart';
import 'package:petrimonium_health/core/profile/health_profile.dart';
import 'package:petrimonium_health/features/health/data/health_repository.dart';
import 'package:petrimonium_health/features/health/domain/category_catalog.dart';
import 'package:petrimonium_health/features/health/domain/health_models.dart';
import 'package:petrimonium_health/features/health/presentation/health_controller.dart';

/// HealthController owns the account's money. Twenty-seven of its methods had
/// no direct test — only whatever a widget test happened to drive — so the
/// invariants below were held by reading alone.
void main() {
  late _Repository repository;
  late HealthController controller;

  const ptProfile = HealthProfile(
    country: CountryCode.portugal,
    primaryCurrency: CurrencyCode.eur,
    interfaceLocale: InterfaceLocale.ptPt,
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    repository = _Repository();
    controller = HealthController(repository: repository, localeController: LocaleController());
  });

  group('signing in', () {
    test('an account with no profile lands on onboarding, not home', () async {
      repository.profile = null;
      repository.pet = null;

      await controller.login('ana@example.com', 'secret');

      expect(controller.stage, AppStage.onboarding);
      expect(controller.onboardingStep, OnboardingStep.petSetup);
      expect(controller.onboardingHadPetStep, isTrue);
    });

    test('an account that already has a Pet skips the Pet step', () async {
      repository.profile = null;
      repository.pet = const PetIdentity(name: 'Fred', species: 'FOX');

      await controller.login('ana@example.com', 'secret');

      expect(controller.stage, AppStage.onboarding);
      expect(controller.onboardingStep, OnboardingStep.quickSetup);
      expect(controller.onboardingHadPetStep, isFalse, reason: 'the progress dots must say 1 step, not 2');
    });

    test('a profile sends the user home and loads the month', () async {
      repository.profile = ptProfile;

      await controller.login('ana@example.com', 'secret');

      expect(controller.stage, AppStage.home);
      expect(controller.summary, isNotNull);
    });

    test('a failing pet or identity lookup does not block the sign-in', () async {
      repository.profile = ptProfile;
      repository.petThrows = true;
      repository.currentUserThrows = true;

      await controller.login('ana@example.com', 'secret');

      expect(controller.stage, AppStage.home, reason: 'neither lookup gates the session');
      expect(controller.pet, isNull);
      expect(controller.account, isNull);
    });

    test('a failed sign-in reports the error, clears busy, and rethrows', () async {
      repository.loginThrows = true;

      await expectLater(controller.login('ana@example.com', 'wrong'), throwsA(isA<Exception>()));

      expect(controller.busy, isFalse);
      expect(controller.error, contains('bad credentials'));
      expect(controller.stage, isNot(AppStage.home));
    });

    test('restore without a session goes straight to signed out', () async {
      repository.session = false;

      await controller.restore();

      expect(controller.stage, AppStage.signedOut);
    });
  });

  group('refreshData', () {
    setUp(() async {
      repository.profile = ptProfile;
      await controller.login('ana@example.com', 'secret');
    });

    test('a payload in the wrong currency is reported, never silently mixed', () async {
      repository.summaryCurrency = CurrencyCode.brl;

      await controller.refreshData();

      expect(controller.error, isNotNull, reason: 'BRL amounts under an EUR profile would restate the balance');
      expect(controller.refreshing, isFalse);
    });

    test('an account in the wrong currency is caught too, not just the summary', () async {
      repository.accountCurrency = CurrencyCode.brl;

      await controller.refreshData();

      expect(controller.error, isNotNull);
    });

    test('a second refresh while one is in flight is dropped', () async {
      repository.holdAccounts = true;
      final first = controller.refreshData();
      final callsDuring = repository.getAccountsCalls;

      await controller.refreshData();
      expect(repository.getAccountsCalls, callsDuring, reason: 'the in-flight guard held');

      repository.releaseAccounts();
      await first;
    });

    test('without a profile it is a no-op rather than an error', () async {
      controller.profile = null;
      repository.getAccountsCalls = 0;

      await controller.refreshData();

      expect(repository.getAccountsCalls, 0);
      expect(controller.error, isNull);
    });
  });

  group('debts and income', () {
    setUp(() async {
      repository.profile = ptProfile;
      await controller.login('ana@example.com', 'secret');
    });

    test('a recurring debt becomes a recurrence, not a transaction', () async {
      await controller.addDebt(
        category: DebtCategory.values.first,
        name: 'Renda',
        value: Money.fromDecimal('500.00', CurrencyCode.eur),
        recurring: true,
      );

      expect(repository.createdRecurrences, 1);
      expect(repository.createdTransactions, 0);
    });

    test('a one-off debt becomes a planned expense', () async {
      await controller.addDebt(
        category: DebtCategory.values.first,
        name: 'Dentista',
        value: Money.fromDecimal('80.00', CurrencyCode.eur),
        recurring: false,
      );

      expect(repository.createdTransactions, 1);
      expect(repository.lastTransactionType, TransactionType.expense);
      expect(
        repository.lastTransactionStatus,
        TransactionStatus.planned,
        reason: 'a debt is something owed, not money already spent',
      );
    });

    test('a one-off income is a planned INCOME', () async {
      await controller.addIncome(
        category: IncomeCategory.values.first,
        name: 'Freelance',
        value: Money.fromDecimal('300.00', CurrencyCode.eur),
        recurring: false,
      );

      expect(repository.lastTransactionType, TransactionType.income);
      expect(repository.lastTransactionStatus, TransactionStatus.planned);
    });

    test('an existing account is reused instead of opening a second one', () async {
      expect(controller.accounts, isNotEmpty, reason: 'the fixture already has one');
      repository.createdAccounts = 0;

      await controller.addDebt(
        category: DebtCategory.values.first,
        name: 'Renda',
        value: Money.fromDecimal('500.00', CurrencyCode.eur),
        recurring: false,
      );

      expect(repository.createdAccounts, 0);
    });

    test('with no account at all, exactly one default account is opened', () async {
      repository.accounts = const [];
      await controller.refreshData();
      repository.createdAccounts = 0;

      await controller.addDebt(
        category: DebtCategory.values.first,
        name: 'Renda',
        value: Money.fromDecimal('500.00', CurrencyCode.eur),
        recurring: false,
      );

      expect(repository.createdAccounts, 1);
    });
  });

  group('signing out', () {
    test('logout clears the previous account\'s data and session', () async {
      repository.profile = ptProfile;
      await controller.login('ana@example.com', 'secret');
      expect(controller.summary, isNotNull);

      await controller.logout();

      expect(controller.stage, AppStage.signedOut);
      expect(controller.profile, isNull);
      expect(controller.account, isNull);
      expect(controller.pet, isNull);
      expect(controller.summary, isNull);
      expect(controller.accounts, isEmpty);
      expect(controller.transactions, isEmpty);
      expect(controller.recurrences, isEmpty);
      expect(controller.cards, isEmpty);
      expect(controller.error, isNull);
      expect(controller.onboardingHadPetStep, isFalse);
    });
  });
}

class _Repository implements HealthRepository {
  bool session = true;
  HealthProfile? profile;
  PetIdentity? pet;
  bool petThrows = false;
  bool currentUserThrows = false;
  bool loginThrows = false;

  CurrencyCode summaryCurrency = CurrencyCode.eur;
  CurrencyCode accountCurrency = CurrencyCode.eur;

  int getAccountsCalls = 0;
  int createdRecurrences = 0;
  int createdTransactions = 0;
  int createdAccounts = 0;
  TransactionType? lastTransactionType;
  TransactionStatus? lastTransactionStatus;

  bool holdAccounts = false;
  Completer<void>? _gate;
  void releaseAccounts() => _gate?.complete();

  List<HealthAccount>? accounts;

  HealthAccount _account({CurrencyCode? currency, int id = 1}) {
    final c = currency ?? accountCurrency;
    return HealthAccount(
      id: id,
      name: 'Conta à ordem',
      type: AccountType.checking,
      initialBalance: Money.zero(c),
      balanceReferenceDate: DateTime(2026, 9, 1),
      currentBalance: Money.zero(c),
      archived: false,
    );
  }

  @override
  Future<bool> hasSession() async => session;

  @override
  Future<void> login(String email, String password) async {
    if (loginThrows) throw Exception('bad credentials');
  }

  @override
  Future<HealthProfile?> getProfile() async => profile;

  @override
  Future<PetIdentity?> getPet() async {
    if (petThrows) throw Exception('pet unavailable');
    return pet;
  }

  @override
  Future<AccountIdentity?> getCurrentUser() async {
    if (currentUserThrows) throw Exception('identity unavailable');
    return const AccountIdentity(username: 'Ana', email: 'ana@example.com');
  }

  @override
  Future<List<HealthAccount>> getAccounts() async {
    getAccountsCalls++;
    if (holdAccounts) {
      _gate = Completer<void>();
      await _gate!.future;
    }
    return accounts ?? [_account()];
  }

  @override
  Future<List<HealthTransaction>> getTransactions({
    DateTime? from,
    DateTime? to,
    int? accountId,
    String? category,
    TransactionStatus? status,
  }) async => const [];

  @override
  Future<List<HealthCard>> getCards() async => const [];

  @override
  Future<List<HealthRecurrence>> getRecurrences() async => const [];

  @override
  Future<MonthlySummary> getSummary(DateTime month) async => MonthlySummary.empty(summaryCurrency, month);

  @override
  Future<HealthAccount> createAccount({
    required String name,
    required AccountType type,
    required Money initialBalance,
    required DateTime balanceReferenceDate,
  }) async {
    createdAccounts++;
    final created = _account(id: 99);
    accounts = [...?accounts, created];
    return created;
  }

  @override
  Future<HealthRecurrence> createRecurrence({
    required int accountId,
    required TransactionType type,
    required Money amount,
    required String description,
    required String category,
    required int dayOfMonth,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    createdRecurrences++;
    return HealthRecurrence(
      id: createdRecurrences,
      accountId: accountId,
      type: type,
      amount: amount,
      description: description,
      category: category,
      dayOfMonth: dayOfMonth,
      startDate: startDate,
    );
  }

  @override
  Future<HealthTransaction> createTransaction({
    required int accountId,
    required TransactionType type,
    required TransactionStatus status,
    required Money amount,
    required String description,
    required String category,
    required DateTime date,
  }) async {
    createdTransactions++;
    lastTransactionType = type;
    lastTransactionStatus = status;
    return HealthTransaction(
      id: createdTransactions,
      accountId: accountId,
      type: type,
      status: status,
      amount: amount,
      description: description,
      category: category,
      date: date,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
