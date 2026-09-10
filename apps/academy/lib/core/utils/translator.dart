import 'package:flutter/foundation.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import '../constants/app_strings.dart';

/// App-wide translator. pt-BR is the product's default language; en/es are
/// offered through the Settings screen.
///
/// The lookup itself lives in [TranslatorEngine]; this class is the product's
/// half of it. Copy every Petrimonium product words the same way comes from
/// `sharedCopy`; what stays here is only what this product says differently -
/// its brand voice, and the screens the other products do not have. Adding a
/// string that the sibling app already words identically belongs in
/// `sharedCopy`, not here.
///
/// The static surface is unchanged on purpose: 601 call sites already say
/// `Translator.translate(AppStrings.x)`, and none of them had to move.
class Translator {
  Translator._();

  static const String defaultLanguage = 'pt';
  static const Set<String> supportedLanguages = {'pt', 'pt_PT', 'en', 'es'};

  static final TranslatorEngine _engine = TranslatorEngine(
    base: sharedCopy,
    overrides: _productCopy,
    defaultLanguage: defaultLanguage,
    supportedLanguages: supportedLanguages,
  );

  static ValueNotifier<String> get languageNotifier => _engine.languageNotifier;

  static String get currentLanguage => _engine.currentLanguage;

  /// Synchronous setter kept for tests and simple in-memory switches.
  /// Prefer [setLanguage] in the app so the preference is persisted.
  static set currentLanguage(String language) => _engine.currentLanguage = language;

  /// Loads the persisted language preference. Call once during app startup,
  /// before the first screen is built.
  static Future<void> load() => _engine.load();

  /// Updates the current language and persists it locally.
  /// Does not call the backend — callers that need the preference synced
  /// server-side (e.g. the Settings screen) should do that separately.
  static Future<void> setLanguage(String language) => _engine.setLanguage(language);

  /// [params] fills `{token}` placeholders in the translated string (e.g.
  /// `{petName}`) — used for copy that embeds the user's chosen pet name,
  /// which can't be baked into the static translation map.
  static String translate(String key, {Map<String, String>? params}) => _engine.translate(key, params: params);

  /// Test-only escape hatch onto the *merged* catalogue (shared + product), so
  /// `translator_test.dart` keeps asserting parity over exactly what the app
  /// resolves at runtime, not over this file alone.
  static Map<String, Map<String, String>> get debugLocalizedValues => _engine.debugLocalizedValues;

  /// Test-only view of just this product's half, so a test can assert the
  /// halves stay disjoint — see `translator_test.dart`.
  static Map<String, Map<String, String>> get debugProductCopy => _productCopy;

  /// This product's own wording. Everything else comes from `sharedCopy`.
  static const Map<String, Map<String, String>> _productCopy = {
    'pt': {
      AppStrings.brandTitle: 'Petrimonium',
      AppStrings.brandTagline: 'Aprenda a investir jogando',
      AppStrings.createAccount: 'Criar Conta',
      AppStrings.fillDetails: 'Preencha seus dados',
      AppStrings.alreadyHaveAccount: 'Já tem conta? Entrar',
      AppStrings.meetPetTitle: 'Escolha seu parceiro de jornada',
      AppStrings.meetPetIntro: 'Ele evolui com o que você aprende — nunca com quanto você tem.',
      AppStrings.financialGoalTitle: 'Qual é o seu objetivo agora?',
      AppStrings.financialGoalSubtitle: 'Isso ajusta sua trilha. Você pode mudar depois.',
      AppStrings.welcomeHeadline: 'Aprenda finanças praticando com segurança.',
      AppStrings.welcomeSubheadline: 'PETRIMONIUM ACADEMY',
      AppStrings.academyIntroTitle: 'Sua trilha começa aqui',
      AppStrings.academyIntroSubtitle: 'O resto libera conforme você avança — sem pular etapas.',
      AppStrings.academyIntroStartsNow: 'começa agora',
      AppStrings.academyIntroMentorIntro: 'Vamos começar por {module}. {count} — dá pra começar agora.',
      AppStrings.academyIntroLessonSingular: 'aula',
      AppStrings.academyIntroLessonPlural: 'aulas',
      AppStrings.gamificationIntroTitle: 'Como você progride aqui',
      AppStrings.gamificationIntroXpRuleTitle: 'XP por aprender',
      AppStrings.gamificationIntroXpRuleBody:
          'Você ganha XP completando aulas e práticas — nunca por valorização, aporte ou operação.',
      AppStrings.gamificationIntroStreakRuleTitle: 'Ofensiva sem punição',
      AppStrings.gamificationIntroStreakRuleBody:
          'Perder um dia não zera seu progresso nem te penaliza — o pet só fica com saudade.',
      AppStrings.gamificationIntroCompareRuleTitle: 'Sem comparação entre pessoas',
      AppStrings.gamificationIntroCompareRuleBody:
          'Seu progresso é só seu. Não existe ranking de patrimônio ou retorno aqui.',
      AppStrings.timeHorizonTitle: 'Para quando é esse objetivo?',
      AppStrings.timeHorizonSubtitle: 'Sem certeza? Tudo bem, é só um ponto de partida.',
      AppStrings.experienceLevelTitle: 'Como está sua experiência hoje?',
      AppStrings.experienceLevelSubtitle: 'Assim a Academy não te ensina o que você já sabe.',
      AppStrings.academyLessonCompleteTitle: 'Aula concluída!',
      AppStrings.academyLearningProgressPill: '+{xp} XP · progresso de aprendizado',
      AppStrings.academyContentLabel: 'CONTEÚDO EDUCATIVO',
      AppStrings.academyExampleLabel: 'EXEMPLO',
      AppStrings.academyLessonOfLabel: 'Aula {n} de {total}',
      AppStrings.mentorInterpretationLabel: 'MENTOR · INTERPRETAÇÃO DE IA',
      AppStrings.mentorTodayLabel: 'Hoje',
      AppStrings.academyAllModulesTitle: 'Sua trilha completa',
      AppStrings.walletBridgeCtaLabel: 'Ver isso na sua carteira real',
      AppStrings.walletBridgeComingSoon: 'Em breve na Wallet',
      AppStrings.simulatedWalletTitle: 'Carteira Simulada',
      AppStrings.simulatedWalletDisclaimer:
          'Dinheiro virtual, sem execução real. Sem conexão com B3, corretora, banco ou exchange. Não é recomendação financeira — resultados simulados não garantem resultados reais.',
      AppStrings.simulatedWalletVirtualBalanceLabel: 'Saldo virtual',
      AppStrings.simulatedWalletPositionsTitle: 'Posições simuladas',
      AppStrings.simulatedWalletNoPositions:
          'Você ainda não tem posições simuladas. Que tal registrar sua primeira operação?',
      AppStrings.simulatedWalletNewOrderAction: 'Nova operação',
      AppStrings.simulatedWalletResetAction: 'Reiniciar simulação',
      AppStrings.simulatedWalletResetConfirmTitle: 'Reiniciar simulação?',
      AppStrings.simulatedWalletResetConfirmMessage:
          'Isso apaga todas as posições e operações simuladas e restaura o saldo virtual inicial. Essa ação não pode ser desfeita.',
      AppStrings.simulatedWalletResetConfirmAction: 'Reiniciar',
      AppStrings.simulatedWalletResetSuccess: 'Simulação reiniciada',
      AppStrings.simulatedOrderScreenTitle: 'Nova operação simulada',
      AppStrings.simulatedOrderSearchHint: 'Buscar ativo (ex: PETR4)',
      AppStrings.simulatedOrderBuyLabel: 'Comprar',
      AppStrings.simulatedOrderSellLabel: 'Vender',
      AppStrings.simulatedOrderQuantityLabel: 'Quantidade',
      AppStrings.simulatedOrderReferencePriceLabel: 'Preço de referência (simulado)',
      AppStrings.simulatedOrderConfirmAction: 'Confirmar operação simulada',
      AppStrings.simulatedOrderSuccessMessage: 'Operação simulada registrada',
      AppStrings.simulatedOrderSelectAssetFirst: 'Busque e selecione um ativo primeiro',
      AppStrings.simulatedWalletAllocationTitle: 'Alocação simulada',
      AppStrings.homeKnowledgeMapLabel: 'SUA TRILHA',
      AppStrings.homeViewFullAcademyCta: 'Ver todas as escolas',
      AppStrings.homeGreetingWithName: 'Bem-vindo de volta, {name}',
      AppStrings.homeStreakDaysLabel: '{days} dias',
      AppStrings.homeContinueGoalSubtitle: 'Baseado no seu objetivo: {goal}',
      AppStrings.homeMentorReasonContinue: 'Baseado na sua última aula concluída.',
      AppStrings.homeMentorReasonReview: 'Baseado em conceitos pendentes de revisão.',
      AppStrings.homeMentorReasonReturn: 'Baseado no tempo desde sua última visita.',
      AppStrings.homeMentorSourcesLabel: 'Fontes consultadas (RAG)',
      AppStrings.homeMentorSourceContinue1: 'Sua última aula concluída',
      AppStrings.homeMentorSourceContinue2: 'Seu progresso na trilha atual',
      AppStrings.homeMentorSourceContinue3: 'Guia interno de sequenciamento de conteúdo',
      AppStrings.homeMentorSourceReview1: 'Aulas com desempenho baixo no quiz',
      AppStrings.homeMentorSourceReview2: 'Seu histórico de revisões',
      AppStrings.homeMentorSourceReview3: 'Guia interno de repetição espaçada',
      AppStrings.homeMentorSourceReturn1: 'Tempo desde sua última visita',
      AppStrings.homeMentorSourceReturn2: 'Sua trilha em andamento',
      AppStrings.homeMentorSourceReturn3: 'Guia interno de retomada após pausa',
      AppStrings.mentorHeaderTitle: 'Seu Mentor',
      AppStrings.mentorHeaderSubtitle: 'Tira dúvidas e explica conceitos — não é conselho financeiro',
      AppStrings.mentorEmptyStateGreeting: 'Oi! Posso te ajudar a entender qualquer conceito da sua trilha.',
      AppStrings.mentorEmptyStateSubtitle: 'Não vou te dizer o que fazer com seu dinheiro — só explicar, no seu ritmo.',
      AppStrings.labSimulatedDataBadge: 'Simulação — dados fictícios, não é sua carteira real',
      AppStrings.portfolioMilestoneUnlocked: 'Novo marco: {title}',
    },
    // Português europeu. Deliberadamente esparso: só as entradas que diferem
    // do pt-BR. Todo o resto resolve pelo fallback de [translate] para o bloco
    // 'pt', que aqui é o comportamento certo — as duas variantes partilham a
    // maior parte da língua, e uma chave em falta não é um buraco de tradução.
    // O teste 'pt_PT só define chaves que pt também define' impede órfãs.
    'pt_PT': {
      AppStrings.brandTagline: 'Aprenda a investir a jogar',
      AppStrings.gamificationIntroCompareRuleBody:
          'O seu progresso é só seu. Não existe ranking de património ou retorno aqui.',
    },
    'en': {
      AppStrings.brandTitle: 'Petrimonium',
      AppStrings.brandTagline: 'Learn investing by playing',
      AppStrings.createAccount: 'Create Account',
      AppStrings.fillDetails: 'Fill in your details',
      AppStrings.alreadyHaveAccount: 'Already have an account? Login',
      AppStrings.meetPetTitle: 'Choose your journey partner',
      AppStrings.meetPetIntro: 'It grows with what you learn — never with how much you have.',
      AppStrings.financialGoalTitle: "What's your goal right now?",
      AppStrings.financialGoalSubtitle: 'This shapes your path. You can change it later.',
      AppStrings.welcomeHeadline: 'Learn finance by practicing, safely.',
      AppStrings.welcomeSubheadline: 'PETRIMONIUM ACADEMY',
      AppStrings.academyIntroTitle: 'Your track starts here',
      AppStrings.academyIntroSubtitle: 'The rest unlocks as you go — no skipping steps.',
      AppStrings.academyIntroStartsNow: 'starts now',
      AppStrings.academyIntroMentorIntro: "Let's start with {module}. {count} — you can do it now.",
      AppStrings.academyIntroLessonSingular: 'lesson',
      AppStrings.academyIntroLessonPlural: 'lessons',
      AppStrings.gamificationIntroTitle: 'How you progress here',
      AppStrings.gamificationIntroXpRuleTitle: 'XP for learning',
      AppStrings.gamificationIntroXpRuleBody:
          'You earn XP by completing lessons and practice — never for returns, deposits, or trades.',
      AppStrings.gamificationIntroStreakRuleTitle: 'No-punishment streak',
      AppStrings.gamificationIntroStreakRuleBody:
          "Missing a day doesn't reset your progress or penalize you — your pet just misses you.",
      AppStrings.gamificationIntroCompareRuleTitle: 'No comparing with others',
      AppStrings.gamificationIntroCompareRuleBody:
          "Your progress is yours alone. There's no net worth or returns leaderboard here.",
      AppStrings.timeHorizonTitle: 'When is this goal for?',
      AppStrings.timeHorizonSubtitle: "Not sure? That's fine, it's just a starting point.",
      AppStrings.experienceLevelTitle: "How's your experience today?",
      AppStrings.experienceLevelSubtitle: "This way the Academy won't teach you what you already know.",
      AppStrings.academyLessonCompleteTitle: 'Lesson complete!',
      AppStrings.academyLearningProgressPill: '+{xp} XP · learning progress',
      AppStrings.academyContentLabel: 'EDUCATIONAL CONTENT',
      AppStrings.academyExampleLabel: 'EXAMPLE',
      AppStrings.academyLessonOfLabel: 'Lesson {n} of {total}',
      AppStrings.mentorInterpretationLabel: 'MENTOR · AI INTERPRETATION',
      AppStrings.mentorTodayLabel: 'Today',
      AppStrings.academyAllModulesTitle: 'Your full track',
      AppStrings.walletBridgeCtaLabel: 'See this in your real portfolio',
      AppStrings.walletBridgeComingSoon: 'Coming soon in Wallet',
      AppStrings.simulatedWalletTitle: 'Simulated Wallet',
      AppStrings.simulatedWalletDisclaimer:
          'Virtual money, no real execution. No connection to any exchange, broker, or bank. Not financial advice — simulated results do not guarantee real results.',
      AppStrings.simulatedWalletVirtualBalanceLabel: 'Virtual balance',
      AppStrings.simulatedWalletPositionsTitle: 'Simulated positions',
      AppStrings.simulatedWalletNoPositions:
          "You don't have any simulated positions yet. How about placing your first order?",
      AppStrings.simulatedWalletNewOrderAction: 'New order',
      AppStrings.simulatedWalletResetAction: 'Reset simulation',
      AppStrings.simulatedWalletResetConfirmTitle: 'Reset simulation?',
      AppStrings.simulatedWalletResetConfirmMessage:
          'This erases every simulated position and order and restores the starting virtual balance. This cannot be undone.',
      AppStrings.simulatedWalletResetConfirmAction: 'Reset',
      AppStrings.simulatedWalletResetSuccess: 'Simulation reset',
      AppStrings.simulatedOrderScreenTitle: 'New simulated order',
      AppStrings.simulatedOrderSearchHint: 'Search an asset (e.g. PETR4)',
      AppStrings.simulatedOrderBuyLabel: 'Buy',
      AppStrings.simulatedOrderSellLabel: 'Sell',
      AppStrings.simulatedOrderQuantityLabel: 'Quantity',
      AppStrings.simulatedOrderReferencePriceLabel: 'Reference price (simulated)',
      AppStrings.simulatedOrderConfirmAction: 'Confirm simulated order',
      AppStrings.simulatedOrderSuccessMessage: 'Simulated order placed',
      AppStrings.simulatedOrderSelectAssetFirst: 'Search and select an asset first',
      AppStrings.simulatedWalletAllocationTitle: 'Simulated allocation',
      AppStrings.homeKnowledgeMapLabel: 'YOUR TRACK',
      AppStrings.homeViewFullAcademyCta: 'See all schools',
      AppStrings.homeGreetingWithName: 'Welcome back, {name}',
      AppStrings.homeStreakDaysLabel: '{days} days',
      AppStrings.homeContinueGoalSubtitle: 'Based on your goal: {goal}',
      AppStrings.homeMentorReasonContinue: 'Based on your last completed lesson.',
      AppStrings.homeMentorReasonReview: 'Based on concepts due for review.',
      AppStrings.homeMentorReasonReturn: "Based on how long it's been since your last visit.",
      AppStrings.homeMentorSourcesLabel: 'Sources consulted (RAG)',
      AppStrings.homeMentorSourceContinue1: 'Your last completed lesson',
      AppStrings.homeMentorSourceContinue2: 'Your progress on the current path',
      AppStrings.homeMentorSourceContinue3: 'Internal content-sequencing guide',
      AppStrings.homeMentorSourceReview1: 'Lessons with low quiz performance',
      AppStrings.homeMentorSourceReview2: 'Your review history',
      AppStrings.homeMentorSourceReview3: 'Internal spaced-repetition guide',
      AppStrings.homeMentorSourceReturn1: 'Time since your last visit',
      AppStrings.homeMentorSourceReturn2: 'Your path in progress',
      AppStrings.homeMentorSourceReturn3: 'Internal return-after-pause guide',
      AppStrings.mentorHeaderTitle: 'Your Mentor',
      AppStrings.mentorHeaderSubtitle: 'Answers questions and explains concepts — not financial advice',
      AppStrings.mentorEmptyStateGreeting: 'Hi! I can help you understand any concept from your path.',
      AppStrings.mentorEmptyStateSubtitle:
          "I won't tell you what to do with your money — just explain, at your own pace.",
      AppStrings.labSimulatedDataBadge: 'Simulation — fictional data, not your real portfolio',
      AppStrings.portfolioMilestoneUnlocked: 'New milestone: {title}',
    },
    'es': {
      AppStrings.brandTitle: 'Petrimonium',
      AppStrings.brandTagline: 'Aprende a invertir jugando',
      AppStrings.createAccount: 'Crear Cuenta',
      AppStrings.fillDetails: 'Completa tus datos',
      AppStrings.alreadyHaveAccount: '¿Ya tienes cuenta? Entrar',
      AppStrings.meetPetTitle: 'Elige tu compañero de viaje',
      AppStrings.meetPetIntro: 'Evoluciona con lo que aprendes — nunca con cuánto tienes.',
      AppStrings.financialGoalTitle: '¿Cuál es tu objetivo ahora?',
      AppStrings.financialGoalSubtitle: 'Esto ajusta tu camino. Puedes cambiarlo después.',
      AppStrings.welcomeHeadline: 'Aprende finanzas practicando con seguridad.',
      AppStrings.welcomeSubheadline: 'PETRIMONIUM ACADEMY',
      AppStrings.academyIntroTitle: 'Tu camino comienza aquí',
      AppStrings.academyIntroSubtitle: 'El resto se desbloquea a medida que avanzas — sin saltar pasos.',
      AppStrings.academyIntroStartsNow: 'empieza ahora',
      AppStrings.academyIntroMentorIntro: 'Empecemos por {module}. {count} — puedes hacerlo ahora.',
      AppStrings.academyIntroLessonSingular: 'lección',
      AppStrings.academyIntroLessonPlural: 'lecciones',
      AppStrings.gamificationIntroTitle: 'Cómo progresas aquí',
      AppStrings.gamificationIntroXpRuleTitle: 'XP por aprender',
      AppStrings.gamificationIntroXpRuleBody:
          'Ganas XP completando lecciones y prácticas — nunca por valorización, aportes u operaciones.',
      AppStrings.gamificationIntroStreakRuleTitle: 'Racha sin penalización',
      AppStrings.gamificationIntroStreakRuleBody:
          'Perder un día no reinicia tu progreso ni te penaliza — tu mascota solo te extraña.',
      AppStrings.gamificationIntroCompareRuleTitle: 'Sin comparación entre personas',
      AppStrings.gamificationIntroCompareRuleBody:
          'Tu progreso es solo tuyo. Aquí no existe un ranking de patrimonio ni de rentabilidad.',
      AppStrings.timeHorizonTitle: '¿Para cuándo es ese objetivo?',
      AppStrings.timeHorizonSubtitle: '¿No estás seguro? Está bien, es solo un punto de partida.',
      AppStrings.experienceLevelTitle: '¿Cómo está tu experiencia hoy?',
      AppStrings.experienceLevelSubtitle: 'Así la Academy no te enseña lo que ya sabes.',
      AppStrings.academyLessonCompleteTitle: '¡Lección completada!',
      AppStrings.academyLearningProgressPill: '+{xp} XP · progreso de aprendizaje',
      AppStrings.academyContentLabel: 'CONTENIDO EDUCATIVO',
      AppStrings.academyExampleLabel: 'EJEMPLO',
      AppStrings.academyLessonOfLabel: 'Lección {n} de {total}',
      AppStrings.mentorInterpretationLabel: 'MENTOR · INTERPRETACIÓN DE IA',
      AppStrings.mentorTodayLabel: 'Hoy',
      AppStrings.academyAllModulesTitle: 'Tu ruta completa',
      AppStrings.walletBridgeCtaLabel: 'Ver esto en tu cartera real',
      AppStrings.walletBridgeComingSoon: 'Próximamente en Wallet',
      AppStrings.simulatedWalletTitle: 'Cartera Simulada',
      AppStrings.simulatedWalletDisclaimer:
          'Dinero virtual, sin ejecución real. Sin conexión con ninguna bolsa, corredora o banco. No es una recomendación financiera — los resultados simulados no garantizan resultados reales.',
      AppStrings.simulatedWalletVirtualBalanceLabel: 'Saldo virtual',
      AppStrings.simulatedWalletPositionsTitle: 'Posiciones simuladas',
      AppStrings.simulatedWalletNoPositions:
          'Aún no tienes posiciones simuladas. ¿Qué tal registrar tu primera operación?',
      AppStrings.simulatedWalletNewOrderAction: 'Nueva operación',
      AppStrings.simulatedWalletResetAction: 'Reiniciar simulación',
      AppStrings.simulatedWalletResetConfirmTitle: '¿Reiniciar simulación?',
      AppStrings.simulatedWalletResetConfirmMessage:
          'Esto borra todas las posiciones y operaciones simuladas y restaura el saldo virtual inicial. Esta acción no se puede deshacer.',
      AppStrings.simulatedWalletResetConfirmAction: 'Reiniciar',
      AppStrings.simulatedWalletResetSuccess: 'Simulación reiniciada',
      AppStrings.simulatedOrderScreenTitle: 'Nueva operación simulada',
      AppStrings.simulatedOrderSearchHint: 'Buscar activo (ej: PETR4)',
      AppStrings.simulatedOrderBuyLabel: 'Comprar',
      AppStrings.simulatedOrderSellLabel: 'Vender',
      AppStrings.simulatedOrderQuantityLabel: 'Cantidad',
      AppStrings.simulatedOrderReferencePriceLabel: 'Precio de referencia (simulado)',
      AppStrings.simulatedOrderConfirmAction: 'Confirmar operación simulada',
      AppStrings.simulatedOrderSuccessMessage: 'Operación simulada registrada',
      AppStrings.simulatedOrderSelectAssetFirst: 'Busca y selecciona un activo primero',
      AppStrings.simulatedWalletAllocationTitle: 'Asignación simulada',
      AppStrings.homeKnowledgeMapLabel: 'TU RUTA',
      AppStrings.homeViewFullAcademyCta: 'Ver todas las escuelas',
      AppStrings.homeGreetingWithName: 'Bienvenido de nuevo, {name}',
      AppStrings.homeStreakDaysLabel: '{days} días',
      AppStrings.homeContinueGoalSubtitle: 'Basado en tu objetivo: {goal}',
      AppStrings.homeMentorWhySeeing: '¿Por qué estoy viendo esto?',
      AppStrings.homeMentorReasonContinue: 'Basado en tu última lección completada.',
      AppStrings.homeMentorReasonReview: 'Basado en conceptos pendientes de repaso.',
      AppStrings.homeMentorReasonReturn: 'Basado en el tiempo desde tu última visita.',
      AppStrings.homeMentorSourcesLabel: 'Fuentes consultadas (RAG)',
      AppStrings.homeMentorSourceContinue1: 'Tu última lección completada',
      AppStrings.homeMentorSourceContinue2: 'Tu progreso en la ruta actual',
      AppStrings.homeMentorSourceContinue3: 'Guía interna de secuenciación de contenido',
      AppStrings.homeMentorSourceReview1: 'Lecciones con bajo desempeño en el quiz',
      AppStrings.homeMentorSourceReview2: 'Tu historial de repasos',
      AppStrings.homeMentorSourceReview3: 'Guía interna de repetición espaciada',
      AppStrings.homeMentorSourceReturn1: 'Tiempo desde tu última visita',
      AppStrings.homeMentorSourceReturn2: 'Tu ruta en curso',
      AppStrings.homeMentorSourceReturn3: 'Guía interna de retorno tras una pausa',
      AppStrings.mentorHeaderTitle: 'Tu Mentor',
      AppStrings.mentorHeaderSubtitle: 'Responde dudas y explica conceptos — no es asesoría financiera',
      AppStrings.mentorEmptyStateGreeting: '¡Hola! Puedo ayudarte a entender cualquier concepto de tu ruta.',
      AppStrings.mentorEmptyStateSubtitle: 'No voy a decirte qué hacer con tu dinero — solo a explicar, a tu ritmo.',
      AppStrings.labSimulatedDataBadge: 'Simulación — datos ficticios, no es tu cartera real',
      AppStrings.portfolioMilestoneUnlocked: 'Nuevo hito: {title}',
    },
  };
}
