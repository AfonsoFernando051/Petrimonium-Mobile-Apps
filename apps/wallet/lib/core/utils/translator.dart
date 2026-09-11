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
/// The static surface is unchanged on purpose: 303 call sites already say
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
      AppStrings.brandTitle: 'Petrimonium Wallet',
      AppStrings.brandTagline: 'Seu patrimônio, com clareza',
      AppStrings.authTabLoginLabel: 'Entrar',
      AppStrings.authTabSignupLabel: 'Criar Conta',
      AppStrings.petSetupTitle: 'Crie seu Pet',
      AppStrings.petSetupSubtitle:
          'Não encontramos um Pet Petrimonium na sua conta. Ele é a mesma identidade na Academy e na Wallet — crie o seu agora.',
      AppStrings.petSetupSpeciesLabel: 'Escolha uma espécie',
      AppStrings.petSetupNameLabel: 'Dê um nome a ele',
      AppStrings.petSetupNameHint: 'Ex.: Nino',
      AppStrings.petSetupFooterNote:
          'Se você já estudou na Academy, seu Pet e progresso aparecem sozinhos aqui — esta etapa não é necessária.',
      AppStrings.petSetupCta: 'Criar meu Pet e continuar',
      AppStrings.petSetupFailedSnack: 'Não foi possível criar seu Pet. Tente novamente.',
      AppStrings.mentorWelcomeHeadline: 'Aqui é sobre o seu patrimônio real.',
      AppStrings.mentorWelcomeParagraph1:
          'Na Academy você aprendeu. Aqui você organiza, acompanha e entende seu dinheiro de verdade.',
      AppStrings.mentorWelcomeParagraph2:
          'Os dados dependem da atualização do mercado — sempre com data e hora visíveis.',
      AppStrings.mentorWelcomeParagraph3:
          'Eu não executo transações nem substituo uma consultoria regulada. Só ajudo a interpretar o que você já tem — sempre citando de onde vem cada informação.',
      AppStrings.mentorWelcomeCta: 'Continuar',
      AppStrings.quickSetupTitle: 'Antes de começar',
      AppStrings.quickSetupSubtitle: 'Só o essencial — dá pra ajustar depois.',
      AppStrings.quickSetupMarketLabel: 'País / mercado',
      AppStrings.quickSetupCurrencyLabel: 'Moeda-base',
      AppStrings.quickSetupFooterNote:
          'Você vai adicionar seus ativos manualmente no próximo passo — nada é importado automaticamente ainda.',
      AppStrings.quickSetupCta: 'Continuar',
      AppStrings.homeGreetingLabel: 'Bem-vindo(a) de volta',
      AppStrings.homeWealthSectionTitle: 'Como está meu patrimônio?',
      AppStrings.homeWealthDataChipLabel: 'DADO',
      AppStrings.homeWealthDataStaleSuffix: 'algumas cotações indisponíveis',
      AppStrings.homeWealthScopePrefix: 'escopo',
      AppStrings.homeChangeSectionTitle: 'O que mudou (últimos 30 dias)',
      AppStrings.homeChangeCalcChipLabel: 'CÁLCULO DETERMINÍSTICO',
      AppStrings.homeChangeComingSoonNote: 'Detalhamento por valorização, aportes e rendimentos — em breve.',
      AppStrings.homeChangeNotEnoughHistoryNote:
          'Ainda não há histórico suficiente nos últimos 30 dias para esse detalhamento.',
      AppStrings.homeChangeValorizacaoLabel: 'Valorização',
      AppStrings.homeChangeAportesLabel: 'Aportes',
      AppStrings.homeChangeRendimentosLabel: 'Rendimentos',
      AppStrings.homeHoldingsSectionTitle: 'Meus ativos',
      AppStrings.homeAddAssetLabel: 'Adicionar',
      AppStrings.portfolioNotConnectedPetCaption:
          'Vamos montar sua carteira juntos? Cadastre seu primeiro ativo — leva menos de um minuto.',
      AppStrings.connectAssetsManualCta: 'Cadastrar ativo manualmente',
      AppStrings.connectAssetsB3Cta: 'Conectar com a B3',
      AppStrings.connectAssetsB3Badge: 'EM BREVE',
      AppStrings.addAssetTitle: 'Adicionar ativo',
      AppStrings.addAssetMentorTip:
          'Cada ativo que você registra deixa sua carteira mais completa — eu uso isso para te dar leituras melhores.',
      AppStrings.addAssetTypeLabel: 'Tipo de investimento',
      AppStrings.addAssetTickerHint: 'Nome/Ticker (ex.: PETR4)',
      AppStrings.addAssetQuantityHint: 'Qtd.',
      AppStrings.addAssetPriceHint: 'Preço (R\$)',
      AppStrings.addAssetDateHint: 'Data de Compra',
      AppStrings.addAssetEstimatedValueLabel: 'VALOR ESTIMADO',
      AppStrings.addAssetPortfolioAfterLabel: 'CARTEIRA APÓS',
      AppStrings.addAssetFooterNote: 'Você pode registrar compras antigas — a data ajuda a calcular seu retorno real.',
      AppStrings.addAssetCta: 'Adicionar ativo',
      AppStrings.addAssetSuccessSnack: 'Ativo adicionado à sua carteira.',
      AppStrings.addAssetFailedSnack: 'Não foi possível adicionar o ativo.',
      AppStrings.addAssetSelectTypeError: 'Selecione um tipo de ativo.',
      AppStrings.addAssetSelectDateError: 'Selecione uma data de compra.',
      AppStrings.addAssetPriceSuggestionTodayLabel: 'Sugestão: cotação de hoje',
      AppStrings.addAssetPriceSuggestionDatePrefix: 'Sugestão: cotação de',
      AppStrings.addAssetNoHistoricalPriceWarning:
          'Não encontramos uma cotação para essa data. Informe o preço de compra manualmente.',
      AppStrings.editAssetTitle: 'Editar ativo',
      AppStrings.editAssetCta: 'Salvar alterações',
      AppStrings.editAssetSuccessSnack: 'Ativo atualizado.',
      AppStrings.editAssetFailedSnack: 'Não foi possível atualizar o ativo.',
      AppStrings.editAssetAction: 'Editar',
      AppStrings.deleteAssetAction: 'Excluir',
      AppStrings.deleteAssetConfirmTitle: 'Excluir este lote?',
      AppStrings.deleteAssetConfirmMessage:
          'Essa compra será removida da sua carteira. Essa ação não pode ser desfeita.',
      AppStrings.deleteAssetConfirmCta: 'Excluir',
      AppStrings.deleteAssetSuccessSnack: 'Lote excluído da sua carteira.',
      AppStrings.deleteAssetFailedSnack: 'Não foi possível excluir o lote.',
      AppStrings.firstValueTitle: 'Sua carteira, pela primeira vez',
      AppStrings.firstValueIntro: 'Aqui está a leitura do que você acabou de registrar.',
      AppStrings.firstValueCompositionTitle: 'COMPOSIÇÃO',
      AppStrings.firstValueMethodologyTitle: 'COMO CALCULAMOS',
      AppStrings.firstValueMethodologyBody:
          'Multiplicamos a quantidade de cada ativo pela cotação mais recente disponível. Um ativo sem cotação aparece sinalizado como tal — nunca como se estivesse parado.',
      AppStrings.firstValueCta: 'Ver minha carteira',
      AppStrings.proventosTitle: 'Proventos',
      AppStrings.proventosSubtitle: 'Dividendos, JCP e rendimentos recebidos',
      AppStrings.proventosReceivedLabel: 'Recebido nos últimos 12 meses',
      AppStrings.proventosNotificationsTitle: 'Próximos proventos',
      AppStrings.proventosNotificationsFooter: 'DADO · datas com base ou anunciadas — podem mudar até a confirmação.',
      AppStrings.profileIdentitySubtitle: 'Petrimonium · Academy + Wallet',
      AppStrings.profileMentorPreferencesLabel: 'Preferências do Mentor',
      AppStrings.profilePrivacyMemoryLabel: 'Privacidade e memória',
      AppStrings.profileCurrencyMarketLabel: 'Moeda-base e mercado',
      AppStrings.profileAppSettingsLabel: 'Configurações do app',
      AppStrings.mentorPreferencesGoalLabel: 'Objetivo financeiro',
      AppStrings.mentorPreferencesHorizonLabel: 'Horizonte de investimento',
      AppStrings.mentorPreferencesSavedSnack: 'Preferências salvas',
      AppStrings.mentorSourcesLabel: 'Fontes',
      AppStrings.mentorSourcePortfolioSummary: 'Sua carteira',
      AppStrings.mentorSourcePortfolioAllocation: 'Sua alocação por categoria',
      AppStrings.mentorSourcePet: 'Seu pet',
      AppStrings.mentorSourceClientGoal: 'Seu objetivo',
      AppStrings.mentorSourceClientHorizon: 'Seu horizonte de investimento',
      AppStrings.mentorSourceClientScreen: 'A tela que você está vendo',
      AppStrings.mentorInterpretationLabel: 'MENTOR · INTERPRETAÇÃO',
      AppStrings.privacyMemoryBody:
          'O Mentor usa seu objetivo e horizonte de investimento como contexto em cada resposta, e guarda suas conversas para você poder retomá-las depois. Ele nunca compartilha esses dados com a Academy nem os usa para decidir por você.',
      AppStrings.privacyMemoryConversationsButton: 'Ver conversas salvas',
      AppStrings.quickSetupSettingsSubtitle: 'Você pode ajustar isso quando quiser.',
      AppStrings.quickSetupSaveCta: 'Salvar',
      AppStrings.quickSetupSavedSnack: 'Preferências salvas',
      AppStrings.meetPetTitle: 'Conheça seu Companheiro',
      AppStrings.meetPetIntro:
          'Sou o seu companheiro financeiro. Vou te ajudar a aprender sobre investimentos, manter a disciplina e comemorar cada conquista da sua jornada.',
      AppStrings.financialGoalTitle: 'Qual será sua primeira missão?',
      AppStrings.financialGoalSubtitle: 'Escolha o que você quer alcançar. Você pode mudar isso depois.',
      AppStrings.welcomeHeadline: 'Sua jornada financeira começa aqui.',
      AppStrings.welcomeSubheadline: 'Aprenda. Invista. Evolua.',
      AppStrings.academyIntroTitle: 'Aprenda no seu ritmo.',
      AppStrings.academyIntroSubtitle: 'Conhecimento antes de investir.',
      AppStrings.gamificationIntroTitle: 'Aprenda. Jogue. Evolua.',
      AppStrings.gamificationIntroSubtitle: 'Transforme conhecimento em progresso.',
      AppStrings.timeHorizonTitle: 'Quando você quer alcançar isso?',
      AppStrings.timeHorizonSubtitle: 'Isso ajusta o ritmo da sua jornada — você pode mudar depois.',
      AppStrings.academyLessonCompleteTitle: 'Lição Concluída!',
      AppStrings.holdingQuoteUnavailable: 'sem cotação',
      AppStrings.holdingNotQuoted: 'não cotado',
      AppStrings.overviewNoInsightsYet: 'Sem insights por enquanto — continue acompanhando sua carteira.',
      AppStrings.academyBridgeCtaLabel: 'Aprender sobre isso no Academy',
      AppStrings.academyBridgeComingSoon: 'Em breve: link para o Academy',
      AppStrings.homeKnowledgeMapLabel: 'SUA TRILHA DE CONHECIMENTO',
      AppStrings.homeViewFullAcademyCta: 'Ver trilha completa',
    },
    // Português europeu. Deliberadamente esparso: só as entradas que diferem
    // do pt-BR. Todo o resto resolve pelo fallback de [translate] para o bloco
    // 'pt', que aqui é o comportamento certo — as duas variantes partilham a
    // maior parte da língua, e uma chave em falta não é um buraco de tradução.
    // O teste 'pt_PT só define chaves que pt também define' impede órfãs.
    'pt_PT': {
      AppStrings.brandTagline: 'O seu património, com clareza',
      AppStrings.quickSetupSaveCta: 'Guardar',
      AppStrings.mentorSourceClientScreen: 'O ecrã que está a ver',
      AppStrings.mentorWelcomeHeadline: 'Aqui é sobre o seu património real.',
      AppStrings.homeWealthSectionTitle: 'Como está o meu património?',
    },
    'en': {
      AppStrings.brandTitle: 'Petrimonium Wallet',
      AppStrings.brandTagline: 'Your wealth, made clear',
      AppStrings.authTabLoginLabel: 'Login',
      AppStrings.authTabSignupLabel: 'Create Account',
      AppStrings.petSetupTitle: 'Create your Pet',
      AppStrings.petSetupSubtitle:
          "We couldn't find a Petrimonium Pet on your account. It's the same identity across the Academy and the Wallet — create yours now.",
      AppStrings.petSetupSpeciesLabel: 'Choose a species',
      AppStrings.petSetupNameLabel: 'Give it a name',
      AppStrings.petSetupNameHint: 'E.g.: Nino',
      AppStrings.petSetupFooterNote:
          "If you've already studied in the Academy, your Pet and progress show up here automatically — this step isn't needed.",
      AppStrings.petSetupCta: 'Create my Pet and continue',
      AppStrings.petSetupFailedSnack: "Couldn't create your Pet. Please try again.",
      AppStrings.mentorWelcomeHeadline: 'This is about your real wealth.',
      AppStrings.mentorWelcomeParagraph1:
          'In the Academy you learned. Here you organize, track and understand your real money.',
      AppStrings.mentorWelcomeParagraph2: 'The data depends on market updates — always shown with a date and time.',
      AppStrings.mentorWelcomeParagraph3:
          "I don't execute transactions or replace a regulated advisor. I just help interpret what you already have — always citing where each piece of information comes from.",
      AppStrings.mentorWelcomeCta: 'Continue',
      AppStrings.quickSetupTitle: 'Before we start',
      AppStrings.quickSetupSubtitle: 'Just the essentials — you can adjust this later.',
      AppStrings.quickSetupMarketLabel: 'Country / market',
      AppStrings.quickSetupCurrencyLabel: 'Base currency',
      AppStrings.quickSetupFooterNote:
          "You'll add your assets manually in the next step — nothing is imported automatically yet.",
      AppStrings.quickSetupCta: 'Continue',
      AppStrings.homeGreetingLabel: 'Welcome back',
      AppStrings.homeWealthSectionTitle: "How's my wealth doing?",
      AppStrings.homeWealthDataChipLabel: 'DATA',
      AppStrings.homeWealthDataStaleSuffix: 'some quotes unavailable',
      AppStrings.homeWealthScopePrefix: 'scope',
      AppStrings.homeChangeSectionTitle: 'What changed (last 30 days)',
      AppStrings.homeChangeCalcChipLabel: 'DETERMINISTIC CALCULATION',
      AppStrings.homeChangeComingSoonNote: 'Breakdown by appreciation, contributions and income — coming soon.',
      AppStrings.homeChangeNotEnoughHistoryNote: 'Not enough history in the last 30 days yet for this breakdown.',
      AppStrings.homeChangeValorizacaoLabel: 'Appreciation',
      AppStrings.homeChangeAportesLabel: 'Contributions',
      AppStrings.homeChangeRendimentosLabel: 'Income',
      AppStrings.homeHoldingsSectionTitle: 'My assets',
      AppStrings.homeAddAssetLabel: 'Add',
      AppStrings.portfolioNotConnectedPetCaption:
          "Shall we build your portfolio together? Add your first asset — it takes less than a minute.",
      AppStrings.connectAssetsManualCta: 'Add an asset manually',
      AppStrings.connectAssetsB3Cta: 'Connect with B3',
      AppStrings.connectAssetsB3Badge: 'COMING SOON',
      AppStrings.addAssetTitle: 'Add asset',
      AppStrings.addAssetMentorTip:
          'Every asset you register makes your portfolio more complete — I use it to give you better insights.',
      AppStrings.addAssetTypeLabel: 'Investment type',
      AppStrings.addAssetTickerHint: 'Name/Ticker (e.g.: PETR4)',
      AppStrings.addAssetQuantityHint: 'Qty.',
      AppStrings.addAssetPriceHint: 'Price (R\$)',
      AppStrings.addAssetDateHint: 'Purchase date',
      AppStrings.addAssetEstimatedValueLabel: 'ESTIMATED VALUE',
      AppStrings.addAssetPortfolioAfterLabel: 'PORTFOLIO AFTER',
      AppStrings.addAssetFooterNote: 'You can register old purchases — the date helps calculate your real return.',
      AppStrings.addAssetCta: 'Add asset',
      AppStrings.addAssetSuccessSnack: 'Asset added to your portfolio.',
      AppStrings.addAssetFailedSnack: "Couldn't add the asset.",
      AppStrings.addAssetSelectTypeError: 'Select an asset type.',
      AppStrings.addAssetSelectDateError: 'Select a purchase date.',
      AppStrings.addAssetPriceSuggestionTodayLabel: "Suggestion: today's quote",
      AppStrings.addAssetPriceSuggestionDatePrefix: 'Suggestion: quote from',
      AppStrings.addAssetNoHistoricalPriceWarning:
          "We couldn't find a quote for that date. Enter the purchase price manually.",
      AppStrings.editAssetTitle: 'Edit asset',
      AppStrings.editAssetCta: 'Save changes',
      AppStrings.editAssetSuccessSnack: 'Asset updated.',
      AppStrings.editAssetFailedSnack: "Couldn't update the asset.",
      AppStrings.editAssetAction: 'Edit',
      AppStrings.deleteAssetAction: 'Delete',
      AppStrings.deleteAssetConfirmTitle: 'Delete this lot?',
      AppStrings.deleteAssetConfirmMessage: 'This purchase will be removed from your portfolio. This cannot be undone.',
      AppStrings.deleteAssetConfirmCta: 'Delete',
      AppStrings.deleteAssetSuccessSnack: 'Lot removed from your portfolio.',
      AppStrings.deleteAssetFailedSnack: "Couldn't delete the lot.",
      AppStrings.firstValueTitle: 'Your portfolio, for the first time',
      AppStrings.firstValueIntro: "Here's the reading of what you just registered.",
      AppStrings.firstValueCompositionTitle: 'COMPOSITION',
      AppStrings.firstValueMethodologyTitle: 'HOW WE CALCULATE IT',
      AppStrings.firstValueMethodologyBody:
          "We multiply each asset's quantity by the most recent quote available. An asset with no quote is flagged as such — never shown as if it hadn't moved.",
      AppStrings.firstValueCta: 'View my portfolio',
      AppStrings.proventosTitle: 'Income',
      AppStrings.proventosSubtitle: 'Dividends, JCP and income received',
      AppStrings.proventosReceivedLabel: 'Received in the last 12 months',
      AppStrings.proventosNotificationsTitle: 'Upcoming income',
      AppStrings.proventosNotificationsFooter: 'DATA · announced or estimated dates — may change until confirmed.',
      AppStrings.profileIdentitySubtitle: 'Petrimonium · Academy + Wallet',
      AppStrings.profileMentorPreferencesLabel: 'Mentor preferences',
      AppStrings.profilePrivacyMemoryLabel: 'Privacy and memory',
      AppStrings.profileCurrencyMarketLabel: 'Base currency and market',
      AppStrings.profileAppSettingsLabel: 'App settings',
      AppStrings.mentorPreferencesGoalLabel: 'Financial goal',
      AppStrings.mentorPreferencesHorizonLabel: 'Investment horizon',
      AppStrings.mentorPreferencesSavedSnack: 'Preferences saved',
      AppStrings.mentorSourcesLabel: 'Sources',
      AppStrings.mentorSourcePortfolioSummary: 'Your portfolio',
      AppStrings.mentorSourcePortfolioAllocation: 'Your allocation by category',
      AppStrings.mentorSourcePet: 'Your pet',
      AppStrings.mentorSourceClientGoal: 'Your goal',
      AppStrings.mentorSourceClientHorizon: 'Your investment horizon',
      AppStrings.mentorSourceClientScreen: "The screen you're viewing",
      AppStrings.mentorInterpretationLabel: 'MENTOR · INTERPRETATION',
      AppStrings.privacyMemoryBody:
          'The Mentor uses your goal and investment horizon as context in every reply, and keeps your conversations so you can pick them back up later. It never shares this data with the Academy or uses it to decide anything for you.',
      AppStrings.privacyMemoryConversationsButton: 'View saved conversations',
      AppStrings.quickSetupSettingsSubtitle: 'You can adjust this whenever you want.',
      AppStrings.quickSetupSaveCta: 'Save',
      AppStrings.quickSetupSavedSnack: 'Preferences saved',
      AppStrings.meetPetTitle: 'Meet Your Companion',
      AppStrings.meetPetIntro:
          "I'm your financial companion. I'll help you learn about investing, stay disciplined and celebrate every achievement along your journey.",
      AppStrings.financialGoalTitle: 'What will be your first mission?',
      AppStrings.financialGoalSubtitle: 'Choose what you want to achieve. You can change it later.',
      AppStrings.welcomeHeadline: 'Your financial journey starts here.',
      AppStrings.welcomeSubheadline: 'Learn. Invest. Evolve.',
      AppStrings.academyIntroTitle: 'Learn at your own pace.',
      AppStrings.academyIntroSubtitle: 'Knowledge before investing.',
      AppStrings.gamificationIntroTitle: 'Learn. Play. Evolve.',
      AppStrings.gamificationIntroSubtitle: 'Turn knowledge into progress.',
      AppStrings.timeHorizonTitle: 'When do you want to achieve it?',
      AppStrings.timeHorizonSubtitle: 'This paces your journey — you can change it later.',
      AppStrings.academyLessonCompleteTitle: 'Lesson Complete!',
      AppStrings.holdingQuoteUnavailable: 'no quote',
      AppStrings.holdingNotQuoted: 'not quoted',
      AppStrings.overviewNoInsightsYet: 'No insights yet — keep tracking your portfolio.',
      AppStrings.academyBridgeCtaLabel: 'Learn about this in Academy',
      AppStrings.academyBridgeComingSoon: 'Coming soon: link to Academy',
      AppStrings.homeKnowledgeMapLabel: 'YOUR KNOWLEDGE MAP',
      AppStrings.homeViewFullAcademyCta: 'View full path',
    },
    'es': {
      AppStrings.brandTitle: 'Petrimonium Wallet',
      AppStrings.brandTagline: 'Tu patrimonio, con claridad',
      AppStrings.authTabLoginLabel: 'Entrar',
      AppStrings.authTabSignupLabel: 'Crear Cuenta',
      AppStrings.petSetupTitle: 'Crea tu Pet',
      AppStrings.petSetupSubtitle:
          'No encontramos un Pet de Petrimonium en tu cuenta. Es la misma identidad en la Academy y en la Wallet — crea el tuyo ahora.',
      AppStrings.petSetupSpeciesLabel: 'Elige una especie',
      AppStrings.petSetupNameLabel: 'Ponle un nombre',
      AppStrings.petSetupNameHint: 'Ej.: Nino',
      AppStrings.petSetupFooterNote:
          'Si ya estudiaste en la Academy, tu Pet y tu progreso aparecen solos aquí — este paso no es necesario.',
      AppStrings.petSetupCta: 'Crear mi Pet y continuar',
      AppStrings.petSetupFailedSnack: 'No se pudo crear tu Pet. Inténtalo de nuevo.',
      AppStrings.mentorWelcomeHeadline: 'Aquí se trata de tu patrimonio real.',
      AppStrings.mentorWelcomeParagraph1:
          'En la Academy aprendiste. Aquí organizas, sigues y entiendes tu dinero de verdad.',
      AppStrings.mentorWelcomeParagraph2:
          'Los datos dependen de la actualización del mercado — siempre con fecha y hora visibles.',
      AppStrings.mentorWelcomeParagraph3:
          'No ejecuto transacciones ni sustituyo una asesoría regulada. Solo ayudo a interpretar lo que ya tienes — siempre citando de dónde viene cada información.',
      AppStrings.mentorWelcomeCta: 'Continuar',
      AppStrings.quickSetupTitle: 'Antes de empezar',
      AppStrings.quickSetupSubtitle: 'Solo lo esencial — se puede ajustar después.',
      AppStrings.quickSetupMarketLabel: 'País / mercado',
      AppStrings.quickSetupCurrencyLabel: 'Moneda base',
      AppStrings.quickSetupFooterNote:
          'Vas a agregar tus activos manualmente en el próximo paso — todavía no se importa nada automáticamente.',
      AppStrings.quickSetupCta: 'Continuar',
      AppStrings.homeGreetingLabel: 'Bienvenido(a) de nuevo',
      AppStrings.homeMentorWhySeeing: '¿Por qué veo esto?',
      AppStrings.homeWealthSectionTitle: '¿Cómo está mi patrimonio?',
      AppStrings.homeWealthDataChipLabel: 'DATO',
      AppStrings.homeWealthDataStaleSuffix: 'algunas cotizaciones no disponibles',
      AppStrings.homeWealthScopePrefix: 'alcance',
      AppStrings.homeChangeSectionTitle: 'Qué cambió (últimos 30 días)',
      AppStrings.homeChangeCalcChipLabel: 'CÁLCULO DETERMINÍSTICO',
      AppStrings.homeChangeComingSoonNote: 'Desglose por valorización, aportes e ingresos — próximamente.',
      AppStrings.homeChangeNotEnoughHistoryNote:
          'Aún no hay suficiente historial en los últimos 30 días para este desglose.',
      AppStrings.homeChangeValorizacaoLabel: 'Valorización',
      AppStrings.homeChangeAportesLabel: 'Aportes',
      AppStrings.homeChangeRendimentosLabel: 'Ingresos',
      AppStrings.homeHoldingsSectionTitle: 'Mis activos',
      AppStrings.homeAddAssetLabel: 'Agregar',
      AppStrings.portfolioNotConnectedPetCaption:
          '¿Armamos tu cartera juntos? Registra tu primer activo — toma menos de un minuto.',
      AppStrings.connectAssetsManualCta: 'Registrar activo manualmente',
      AppStrings.connectAssetsB3Cta: 'Conectar con la B3',
      AppStrings.connectAssetsB3Badge: 'PRÓXIMAMENTE',
      AppStrings.addAssetTitle: 'Agregar activo',
      AppStrings.addAssetMentorTip:
          'Cada activo que registras hace tu cartera más completa — uso esto para darte mejores lecturas.',
      AppStrings.addAssetTypeLabel: 'Tipo de inversión',
      AppStrings.addAssetTickerHint: 'Nombre/Ticker (ej.: PETR4)',
      AppStrings.addAssetQuantityHint: 'Cant.',
      AppStrings.addAssetPriceHint: 'Precio (R\$)',
      AppStrings.addAssetDateHint: 'Fecha de compra',
      AppStrings.addAssetEstimatedValueLabel: 'VALOR ESTIMADO',
      AppStrings.addAssetPortfolioAfterLabel: 'CARTERA DESPUÉS',
      AppStrings.addAssetFooterNote: 'Puedes registrar compras antiguas — la fecha ayuda a calcular tu retorno real.',
      AppStrings.addAssetCta: 'Agregar activo',
      AppStrings.addAssetSuccessSnack: 'Activo agregado a tu cartera.',
      AppStrings.addAssetFailedSnack: 'No se pudo agregar el activo.',
      AppStrings.addAssetSelectTypeError: 'Selecciona un tipo de activo.',
      AppStrings.addAssetSelectDateError: 'Selecciona una fecha de compra.',
      AppStrings.addAssetPriceSuggestionTodayLabel: 'Sugerencia: cotización de hoy',
      AppStrings.addAssetPriceSuggestionDatePrefix: 'Sugerencia: cotización del',
      AppStrings.addAssetNoHistoricalPriceWarning:
          'No encontramos una cotización para esa fecha. Ingresa el precio de compra manualmente.',
      AppStrings.editAssetTitle: 'Editar activo',
      AppStrings.editAssetCta: 'Guardar cambios',
      AppStrings.editAssetSuccessSnack: 'Activo actualizado.',
      AppStrings.editAssetFailedSnack: 'No se pudo actualizar el activo.',
      AppStrings.editAssetAction: 'Editar',
      AppStrings.deleteAssetAction: 'Eliminar',
      AppStrings.deleteAssetConfirmTitle: '¿Eliminar este lote?',
      AppStrings.deleteAssetConfirmMessage: 'Esta compra se eliminará de tu cartera. Esta acción no se puede deshacer.',
      AppStrings.deleteAssetConfirmCta: 'Eliminar',
      AppStrings.deleteAssetSuccessSnack: 'Lote eliminado de tu cartera.',
      AppStrings.deleteAssetFailedSnack: 'No se pudo eliminar el lote.',
      AppStrings.firstValueTitle: 'Tu cartera, por primera vez',
      AppStrings.firstValueIntro: 'Aquí está la lectura de lo que acabas de registrar.',
      AppStrings.firstValueCompositionTitle: 'COMPOSICIÓN',
      AppStrings.firstValueMethodologyTitle: 'CÓMO LO CALCULAMOS',
      AppStrings.firstValueMethodologyBody:
          'Multiplicamos la cantidad de cada activo por la cotización más reciente disponible. Un activo sin cotización aparece señalado como tal — nunca como si no hubiera variado.',
      AppStrings.firstValueCta: 'Ver mi cartera',
      AppStrings.proventosTitle: 'Proventos',
      AppStrings.proventosSubtitle: 'Dividendos, JCP e ingresos recibidos',
      AppStrings.proventosReceivedLabel: 'Recibido en los últimos 12 meses',
      AppStrings.proventosNotificationsTitle: 'Próximos proventos',
      AppStrings.proventosNotificationsFooter:
          'DATO · fechas anunciadas o estimadas — pueden cambiar hasta la confirmación.',
      AppStrings.profileIdentitySubtitle: 'Petrimonium · Academy + Wallet',
      AppStrings.profileMentorPreferencesLabel: 'Preferencias del Mentor',
      AppStrings.profilePrivacyMemoryLabel: 'Privacidad y memoria',
      AppStrings.profileCurrencyMarketLabel: 'Moneda base y mercado',
      AppStrings.profileAppSettingsLabel: 'Configuración de la app',
      AppStrings.mentorPreferencesGoalLabel: 'Objetivo financiero',
      AppStrings.mentorPreferencesHorizonLabel: 'Horizonte de inversión',
      AppStrings.mentorPreferencesSavedSnack: 'Preferencias guardadas',
      AppStrings.mentorSourcesLabel: 'Fuentes',
      AppStrings.mentorSourcePortfolioSummary: 'Tu cartera',
      AppStrings.mentorSourcePortfolioAllocation: 'Tu asignación por categoría',
      AppStrings.mentorSourcePet: 'Tu mascota',
      AppStrings.mentorSourceClientGoal: 'Tu objetivo',
      AppStrings.mentorSourceClientHorizon: 'Tu horizonte de inversión',
      AppStrings.mentorSourceClientScreen: 'La pantalla que estás viendo',
      AppStrings.mentorInterpretationLabel: 'MENTOR · INTERPRETACIÓN',
      AppStrings.privacyMemoryBody:
          'El Mentor usa tu objetivo y horizonte de inversión como contexto en cada respuesta, y guarda tus conversaciones para que puedas retomarlas después. Nunca comparte estos datos con la Academy ni los usa para decidir por ti.',
      AppStrings.privacyMemoryConversationsButton: 'Ver conversaciones guardadas',
      AppStrings.quickSetupSettingsSubtitle: 'Puedes ajustar esto cuando quieras.',
      AppStrings.quickSetupSaveCta: 'Guardar',
      AppStrings.quickSetupSavedSnack: 'Preferencias guardadas',
      AppStrings.meetPetTitle: 'Conoce a tu Compañero',
      AppStrings.meetPetIntro:
          'Soy tu compañero financiero. Te ayudaré a aprender sobre inversiones, mantener la disciplina y celebrar cada logro en tu camino.',
      AppStrings.financialGoalTitle: '¿Cuál será tu primera misión?',
      AppStrings.financialGoalSubtitle: 'Elige lo que quieres lograr. Puedes cambiarlo después.',
      AppStrings.welcomeHeadline: 'Tu viaje financiero comienza aquí.',
      AppStrings.welcomeSubheadline: 'Aprende. Invierte. Evoluciona.',
      AppStrings.academyIntroTitle: 'Aprende a tu ritmo.',
      AppStrings.academyIntroSubtitle: 'Conocimiento antes de invertir.',
      AppStrings.gamificationIntroTitle: 'Aprende. Juega. Evoluciona.',
      AppStrings.gamificationIntroSubtitle: 'Convierte el conocimiento en progreso.',
      AppStrings.timeHorizonTitle: '¿Cuándo quieres lograrlo?',
      AppStrings.timeHorizonSubtitle: 'Esto marca el ritmo de tu viaje — puedes cambiarlo después.',
      AppStrings.academyLessonCompleteTitle: '¡Lección Completada!',
      AppStrings.holdingQuoteUnavailable: 'sin cotización',
      AppStrings.holdingNotQuoted: 'no cotizado',
      AppStrings.overviewNoInsightsYet: 'Aún no hay novedades — sigue acompañando tu cartera.',
      AppStrings.academyBridgeCtaLabel: 'Aprender sobre esto en Academy',
      AppStrings.academyBridgeComingSoon: 'Próximamente: enlace a Academy',
      AppStrings.homeKnowledgeMapLabel: 'TU RUTA DE CONOCIMIENTO',
      AppStrings.homeViewFullAcademyCta: 'Ver ruta completa',
    },
  };
}
