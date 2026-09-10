import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

/// Keys this product looks copy up by.
///
/// The ones aliased to [SharedStrings] are the ecosystem's shared vocabulary;
/// aliasing rather than repeating the literal means a key removed or renamed
/// in the package breaks the build here instead of quietly resolving to
/// nothing at runtime. The ones still declared with a literal are this
/// product's own - screens the sibling app does not have.
class AppStrings {
  AppStrings._();

  static const String welcomeBack = SharedStrings.welcomeBack;
  static const String loginToContinue = SharedStrings.loginToContinue;
  static const String emailOrUserHint = SharedStrings.emailOrUserHint;
  static const String passwordHint = SharedStrings.passwordHint;
  static const String forgotPassword = SharedStrings.forgotPassword;
  static const String noAccountSignUp = SharedStrings.noAccountSignUp;
  static const String loginButton = SharedStrings.loginButton;
  static const String continueWithGoogle = SharedStrings.continueWithGoogle;
  static const String orDivider = SharedStrings.orDivider;
  static const String brandTitle = SharedStrings.brandTitle;
  static const String brandTagline = SharedStrings.brandTagline;
  static const String sharedAccountNotice = SharedStrings.sharedAccountNotice;
  static const String signupSharedAccountNotice = SharedStrings.signupSharedAccountNotice;

  // The Login/Cadastro segmented control shared by LoginCard's LoginForm and
  // SignupForm — a single auth screen, not a separate signup modal, per the
  // Wallet design's tabs.
  static const String authTabLoginLabel = 'authTabLoginLabel';
  static const String authTabSignupLabel = 'authTabSignupLabel';

  // Wallet-first signup pet setup (only step 1 when the account has no Pet
  // yet — see StartRouteResolver): species picker + name field.
  static const String petSetupTitle = 'petSetupTitle';
  static const String petSetupSubtitle = 'petSetupSubtitle';
  static const String petSetupSpeciesLabel = 'petSetupSpeciesLabel';
  static const String petSetupNameLabel = 'petSetupNameLabel';
  static const String petSetupNameHint = 'petSetupNameHint';
  static const String petSetupFooterNote = 'petSetupFooterNote';
  static const String petSetupCta = 'petSetupCta';
  static const String petSetupFailedSnack = 'petSetupFailedSnack';
  static const String petSpecieDog = SharedStrings.petSpecieDog;
  static const String petSpecieCat = SharedStrings.petSpecieCat;
  static const String petSpecieWolf = SharedStrings.petSpecieWolf;
  static const String petSpecieFox = SharedStrings.petSpecieFox;
  static const String petSpecieBear = SharedStrings.petSpecieBear;
  static const String petSpecieLion = SharedStrings.petSpecieLion;
  static const String petSpecieOwl = SharedStrings.petSpecieOwl;

  // Mini onboarding (2 or 3 screens): optional pet setup + Mentor welcome
  // card + quick setup.
  static const String mentorWelcomeHeadline = 'mentorWelcomeHeadline';
  static const String mentorWelcomeParagraph1 = 'mentorWelcomeParagraph1';
  static const String mentorWelcomeParagraph2 = 'mentorWelcomeParagraph2';
  static const String mentorWelcomeParagraph3 = 'mentorWelcomeParagraph3';
  static const String mentorWelcomeCta = 'mentorWelcomeCta';
  static const String quickSetupTitle = 'quickSetupTitle';
  static const String quickSetupSubtitle = 'quickSetupSubtitle';
  static const String quickSetupMarketLabel = 'quickSetupMarketLabel';
  static const String quickSetupCurrencyLabel = 'quickSetupCurrencyLabel';
  static const String quickSetupFooterNote = 'quickSetupFooterNote';
  static const String quickSetupCta = 'quickSetupCta';

  // Home (Wallet) — unified patrimônio + Mentor screen.
  static const String homeGreetingLabel = 'homeGreetingLabel';
  static const String homeMentorWhySeeing = SharedStrings.homeMentorWhySeeing;
  static const String homeWealthSectionTitle = 'homeWealthSectionTitle';
  static const String homeWealthDataChipLabel = 'homeWealthDataChipLabel';
  static const String homeWealthScopePrefix = 'homeWealthScopePrefix';
  static const String homeChangeSectionTitle = 'homeChangeSectionTitle';
  static const String homeChangeCalcChipLabel = 'homeChangeCalcChipLabel';
  static const String homeChangeComingSoonNote = 'homeChangeComingSoonNote';
  static const String homeChangeNotEnoughHistoryNote = 'homeChangeNotEnoughHistoryNote';
  static const String homeChangeValorizacaoLabel = 'homeChangeValorizacaoLabel';
  static const String homeChangeAportesLabel = 'homeChangeAportesLabel';
  static const String homeChangeRendimentosLabel = 'homeChangeRendimentosLabel';
  static const String homeHoldingsSectionTitle = 'homeHoldingsSectionTitle';
  static const String homeAddAssetLabel = 'homeAddAssetLabel';

  // Home — empty-portfolio state: the Pet's speech-bubble caption above its
  // big hero treatment, and the two ways to bring assets in (manual entry
  // works today, B3 sync doesn't exist yet).
  static const String portfolioNotConnectedPetCaption = 'portfolioNotConnectedPetCaption';
  static const String connectAssetsManualCta = 'connectAssetsManualCta';
  static const String connectAssetsB3Cta = 'connectAssetsB3Cta';
  static const String connectAssetsB3Badge = 'connectAssetsB3Badge';

  // AddAssetScreen — Wallet's own single-asset "add asset" screen, distinct
  // from InvestmentConfigurationScreen's Academy-style onboarding wizard.
  static const String addAssetTitle = 'addAssetTitle';
  static const String addAssetMentorTip = 'addAssetMentorTip';
  static const String addAssetTypeLabel = 'addAssetTypeLabel';
  static const String addAssetTickerHint = 'addAssetTickerHint';
  static const String addAssetQuantityHint = 'addAssetQuantityHint';
  static const String addAssetPriceHint = 'addAssetPriceHint';
  static const String addAssetDateHint = 'addAssetDateHint';
  static const String addAssetEstimatedValueLabel = 'addAssetEstimatedValueLabel';
  static const String addAssetPortfolioAfterLabel = 'addAssetPortfolioAfterLabel';
  static const String addAssetFooterNote = 'addAssetFooterNote';
  static const String addAssetCta = 'addAssetCta';
  static const String addAssetSuccessSnack = 'addAssetSuccessSnack';
  static const String addAssetFailedSnack = 'addAssetFailedSnack';
  static const String addAssetSelectTypeError = 'addAssetSelectTypeError';
  static const String addAssetSelectDateError = 'addAssetSelectDateError';

  // Proventos tab + notification popover.
  static const String proventosTitle = 'proventosTitle';
  static const String proventosSubtitle = 'proventosSubtitle';
  static const String proventosReceivedLabel = 'proventosReceivedLabel';
  static const String proventosNotificationsTitle = 'proventosNotificationsTitle';
  static const String proventosNotificationsFooter = 'proventosNotificationsFooter';

  // Perfil + its 3 settings sub-screens.
  static const String profileIdentitySubtitle = 'profileIdentitySubtitle';
  static const String profileMentorPreferencesLabel = 'profileMentorPreferencesLabel';
  static const String profilePrivacyMemoryLabel = 'profilePrivacyMemoryLabel';
  static const String profileCurrencyMarketLabel = 'profileCurrencyMarketLabel';
  static const String profileAppSettingsLabel = 'profileAppSettingsLabel';
  static const String mentorPreferencesGoalLabel = 'mentorPreferencesGoalLabel';
  static const String mentorPreferencesHorizonLabel = 'mentorPreferencesHorizonLabel';
  static const String mentorPreferencesSavedSnack = 'mentorPreferencesSavedSnack';

  // Mentor chat — per-reply source citations ("Por que estou vendo isto?").
  static const String mentorSourcesLabel = 'mentorSourcesLabel';
  static const String mentorSourcePortfolioSummary = 'mentorSourcePortfolioSummary';
  static const String mentorSourcePortfolioAllocation = 'mentorSourcePortfolioAllocation';
  static const String mentorSourcePet = 'mentorSourcePet';
  static const String mentorSourceClientGoal = 'mentorSourceClientGoal';
  static const String mentorSourceClientHorizon = 'mentorSourceClientHorizon';
  static const String mentorSourceClientScreen = 'mentorSourceClientScreen';
  static const String mentorInterpretationLabel = SharedStrings.mentorInterpretationLabel;
  static const String privacyMemoryBody = 'privacyMemoryBody';
  static const String privacyMemoryConversationsButton = 'privacyMemoryConversationsButton';
  static const String quickSetupSettingsSubtitle = 'quickSetupSettingsSubtitle';
  static const String quickSetupSaveCta = 'quickSetupSaveCta';
  static const String quickSetupSavedSnack = 'quickSetupSavedSnack';

  // Signup
  static const String nameHint = SharedStrings.nameHint;
  static const String confirmPasswordHint = SharedStrings.confirmPasswordHint;
  static const String signupButton = SharedStrings.signupButton;

  // Forgot / reset password
  static const String forgotPasswordTitle = SharedStrings.forgotPasswordTitle;
  static const String forgotPasswordSubtitle = SharedStrings.forgotPasswordSubtitle;
  static const String forgotPasswordEmailHint = SharedStrings.forgotPasswordEmailHint;
  static const String forgotPasswordSendButton = SharedStrings.forgotPasswordSendButton;
  static const String forgotPasswordConfirmationMessage = SharedStrings.forgotPasswordConfirmationMessage;
  static const String forgotPasswordHaveCodeLink = SharedStrings.forgotPasswordHaveCodeLink;
  static const String resetPasswordTitle = SharedStrings.resetPasswordTitle;
  static const String resetPasswordSubtitle = SharedStrings.resetPasswordSubtitle;
  static const String resetPasswordTokenHint = SharedStrings.resetPasswordTokenHint;
  static const String resetPasswordNewPasswordHint = SharedStrings.resetPasswordNewPasswordHint;
  static const String resetPasswordSubmitButton = SharedStrings.resetPasswordSubmitButton;
  static const String resetPasswordSuccessMessage = SharedStrings.resetPasswordSuccessMessage;
  static const String resetPasswordMismatchError = SharedStrings.resetPasswordMismatchError;
  static const String resetPasswordFieldsRequiredError = SharedStrings.resetPasswordFieldsRequiredError;

  // Onboarding
  static const String pleaseAnswerAllQuestions = SharedStrings.pleaseAnswerAllQuestions;
  static const String onboardingFailed = SharedStrings.onboardingFailed;
  static const String noQuestionsAvailable = SharedStrings.noQuestionsAvailable;
  static const String failedToLoadQuestions = SharedStrings.failedToLoadQuestions;

  // Pet configuration
  // Reserved for the future persistent Companion Home screen — the
  // onboarding "meet your pet" step below uses `meetPetTitle` instead so the
  // two screens don't share a title before Companion Home exists.
  static const String petProfileTitle = SharedStrings.petProfileTitle;
  static const String failedToSavePet = SharedStrings.failedToSavePet;

  // Meet Your Pet (onboarding)
  static const String meetPetTitle = SharedStrings.meetPetTitle;
  static const String meetPetGreeting = SharedStrings.meetPetGreeting;
  static const String meetPetIntro = SharedStrings.meetPetIntro;
  static const String meetPetNeedName = SharedStrings.meetPetNeedName;
  static const String meetPetSpeciesPrompt = SharedStrings.meetPetSpeciesPrompt;
  static const String meetPetContinue = SharedStrings.meetPetContinue;
  static const String meetPetPreviewTitle = SharedStrings.meetPetPreviewTitle;
  static const String meetPetPreviewCelebrate = SharedStrings.meetPetPreviewCelebrate;
  static const String meetPetPreviewLearn = SharedStrings.meetPetPreviewLearn;
  static const String meetPetPreviewRemember = SharedStrings.meetPetPreviewRemember;

  // Name Your Pet (onboarding)
  static const String namePetTitle = SharedStrings.namePetTitle;
  static const String namePetPrompt = SharedStrings.namePetPrompt;
  static const String namePetHint = SharedStrings.namePetHint;
  static const String namePetContinue = SharedStrings.namePetContinue;
  static const String namePetReaction = SharedStrings.namePetReaction;
  static const String namePetRequiredError = SharedStrings.namePetRequiredError;

  // Financial Goal (onboarding)
  static const String financialGoalTitle = SharedStrings.financialGoalTitle;
  static const String financialGoalSubtitle = SharedStrings.financialGoalSubtitle;
  static const String financialGoalContinue = SharedStrings.financialGoalContinue;

  // Onboarding — shared chrome (Skip/Next reused by Welcome, Academy and
  // Gamification intro screens; Goal/Horizon reuse onboardingNext too).
  static const String onboardingSkip = SharedStrings.onboardingSkip;
  static const String onboardingNext = SharedStrings.onboardingNext;

  // Welcome (onboarding)
  static const String welcomeHeadline = SharedStrings.welcomeHeadline;
  static const String welcomeSubheadline = SharedStrings.welcomeSubheadline;
  static const String welcomeBody = SharedStrings.welcomeBody;
  static const String welcomeCta = SharedStrings.welcomeCta;

  // Academy intro (onboarding)
  static const String academyIntroTitle = SharedStrings.academyIntroTitle;
  static const String academyIntroSubtitle = SharedStrings.academyIntroSubtitle;
  static const String academyIntroBody = SharedStrings.academyIntroBody;
  static const String academyIntroXpBadge = SharedStrings.academyIntroXpBadge;

  // Gamification intro (onboarding)
  static const String gamificationIntroTitle = SharedStrings.gamificationIntroTitle;
  static const String gamificationIntroSubtitle = 'gamificationIntroSubtitle';
  static const String onboardingLevelBadge = SharedStrings.onboardingLevelBadge;

  // Mission reward card — shared by Gamification intro and Journey Ready
  static const String missionCompleteLabel = SharedStrings.missionCompleteLabel;
  static const String missionCompoundInterestTitle = SharedStrings.missionCompoundInterestTitle;

  // Time Horizon (onboarding)
  static const String timeHorizonTitle = SharedStrings.timeHorizonTitle;
  static const String timeHorizonSubtitle = SharedStrings.timeHorizonSubtitle;

  // Journey Ready (onboarding — replaces the old Tutorial's final step)
  static const String journeyReadyTitle = SharedStrings.journeyReadyTitle;
  static const String journeyReadySubtitle = SharedStrings.journeyReadySubtitle;
  static const String journeyReadyGoalLabel = SharedStrings.journeyReadyGoalLabel;
  static const String journeyReadyPathLabel = SharedStrings.journeyReadyPathLabel;
  static const String journeyReadyPathValue = SharedStrings.journeyReadyPathValue;
  static const String journeyReadyCompanionLabel = SharedStrings.journeyReadyCompanionLabel;
  static const String journeyReadyProgressLabel = SharedStrings.journeyReadyProgressLabel;
  static const String journeyReadyFirstMissionLabel = SharedStrings.journeyReadyFirstMissionLabel;
  static const String journeyReadyCta = SharedStrings.journeyReadyCta;

  // Portfolio guidance (onboarding — learn first, portfolio later)
  static const String portfolioChoiceTitle = SharedStrings.portfolioChoiceTitle;
  static const String portfolioChoiceBody = SharedStrings.portfolioChoiceBody;
  static const String portfolioChoiceFootnote = SharedStrings.portfolioChoiceFootnote;
  static const String portfolioGuidanceLearnTitle = SharedStrings.portfolioGuidanceLearnTitle;
  static const String portfolioGuidanceLearnBody = SharedStrings.portfolioGuidanceLearnBody;
  static const String portfolioGuidancePortfolioTitle = SharedStrings.portfolioGuidancePortfolioTitle;
  static const String portfolioGuidancePortfolioBody = SharedStrings.portfolioGuidancePortfolioBody;
  static const String portfolioGuidanceMentorTitle = SharedStrings.portfolioGuidanceMentorTitle;
  static const String portfolioGuidanceMentorBody = SharedStrings.portfolioGuidanceMentorBody;
  static const String portfolioGuidanceContinueButton = SharedStrings.portfolioGuidanceContinueButton;
  static const String importPortfolioButton = SharedStrings.importPortfolioButton;
  static const String addManuallyButton = SharedStrings.addManuallyButton;
  static const String skipForNowButton = SharedStrings.skipForNowButton;
  static const String importComingSoonBody = SharedStrings.importComingSoonBody;

  // Portfolio Activation (Portfolio tab's zero-holdings experience)
  static const String portfolioActivationIntroTitle = SharedStrings.portfolioActivationIntroTitle;
  static const String portfolioActivationIntroBody = SharedStrings.portfolioActivationIntroBody;
  static const String portfolioActivationStartButton = SharedStrings.portfolioActivationStartButton;
  static const String portfolioActivationStatusQuestion = SharedStrings.portfolioActivationStatusQuestion;
  static const String portfolioActivationStatusYes = SharedStrings.portfolioActivationStatusYes;
  static const String portfolioActivationStatusNo = SharedStrings.portfolioActivationStatusNo;
  static const String portfolioActivationConnectTitle = SharedStrings.portfolioActivationConnectTitle;
  static const String portfolioActivationConnectBody = SharedStrings.portfolioActivationConnectBody;
  static const String portfolioActivationAddFirstAssetButton = SharedStrings.portfolioActivationAddFirstAssetButton;
  static const String portfolioActivationLearnTitle = SharedStrings.portfolioActivationLearnTitle;
  static const String portfolioActivationLearnBody = SharedStrings.portfolioActivationLearnBody;
  static const String portfolioActivationStartAcademyButton = SharedStrings.portfolioActivationStartAcademyButton;
  static const String portfolioActivationExploreJourneyButton = SharedStrings.portfolioActivationExploreJourneyButton;
  static const String portfolioActivationReturningNudge = SharedStrings.portfolioActivationReturningNudge;
  static const String portfolioActivationReturningAddAsset = SharedStrings.portfolioActivationReturningAddAsset;
  static const String portfolioActivationReturningGoAcademy = SharedStrings.portfolioActivationReturningGoAcademy;

  // Home — portfolio-not-connected placeholder & suggested actions
  static const String portfolioNotConnectedTitle = SharedStrings.portfolioNotConnectedTitle;
  static const String portfolioNotConnectedBody = SharedStrings.portfolioNotConnectedBody;
  static const String connectInvestmentsButton = SharedStrings.connectInvestmentsButton;
  static const String suggestedActionsTitle = SharedStrings.suggestedActionsTitle;
  static const String suggestedActionCompleteLesson = SharedStrings.suggestedActionCompleteLesson;
  static const String suggestedActionTodayMission = SharedStrings.suggestedActionTodayMission;
  static const String suggestedActionLearnDividends = SharedStrings.suggestedActionLearnDividends;
  static const String suggestedActionFirstQuiz = SharedStrings.suggestedActionFirstQuiz;
  static const String suggestedActionInvestorProfile = SharedStrings.suggestedActionInvestorProfile;
  static const String comingSoonSnack = SharedStrings.comingSoonSnack;

  // Portfolio reminder (gentle nudge after skipping)
  static const String portfolioReminderMessage = SharedStrings.portfolioReminderMessage;
  static const String portfolioReminderCta = SharedStrings.portfolioReminderCta;
  static const String portfolioReminderDismiss = SharedStrings.portfolioReminderDismiss;

  // Settings — companion / rename pet
  static const String companionSectionTitle = SharedStrings.companionSectionTitle;
  static const String renamePetLabel = SharedStrings.renamePetLabel;
  static const String renamePetButton = SharedStrings.renamePetButton;
  static const String renamePetDialogTitle = SharedStrings.renamePetDialogTitle;
  static const String renamePetSuccess = SharedStrings.renamePetSuccess;

  // Settings
  static const String settingsTitle = SharedStrings.settingsTitle;
  static const String settingsSubtitle = SharedStrings.settingsSubtitle;
  static const String languageSectionTitle = SharedStrings.languageSectionTitle;
  static const String languagePt = SharedStrings.languagePt;
  static const String countrySectionTitle = SharedStrings.countrySectionTitle;
  static const String deleteAccountButton = SharedStrings.deleteAccountButton;
  static const String deleteAccountConfirmTitle = SharedStrings.deleteAccountConfirmTitle;
  static const String deleteAccountConfirmMessage = SharedStrings.deleteAccountConfirmMessage;
  static const String countryBrazil = SharedStrings.countryBrazil;
  static const String countryPortugal = SharedStrings.countryPortugal;
  static const String languagePtPt = SharedStrings.languagePtPt;
  static const String languageEn = SharedStrings.languageEn;
  static const String languageEs = SharedStrings.languageEs;
  static const String languageUpdated = SharedStrings.languageUpdated;
  static const String appearanceSectionTitle = SharedStrings.appearanceSectionTitle;
  static const String appearanceLightLabel = SharedStrings.appearanceLightLabel;
  static const String appearanceLightDescription = SharedStrings.appearanceLightDescription;
  static const String appearanceDarkLabel = SharedStrings.appearanceDarkLabel;
  static const String appearanceDarkDescription = SharedStrings.appearanceDarkDescription;
  static const String appearanceSystemLabel = SharedStrings.appearanceSystemLabel;
  static const String appearanceSystemDescription = SharedStrings.appearanceSystemDescription;
  static const String appearanceUpdated = SharedStrings.appearanceUpdated;
  static const String notificationsSectionTitle = SharedStrings.notificationsSectionTitle;
  static const String dailyMissionReminders = SharedStrings.dailyMissionReminders;
  static const String achievementAlerts = SharedStrings.achievementAlerts;
  static const String privacySectionTitle = SharedStrings.privacySectionTitle;
  static const String showOnRankings = SharedStrings.showOnRankings;
  static const String accountSectionTitle = SharedStrings.accountSectionTitle;
  static const String logoutButton = SharedStrings.logoutButton;
  static const String logoutConfirmTitle = SharedStrings.logoutConfirmTitle;
  static const String logoutConfirmMessage = SharedStrings.logoutConfirmMessage;
  static const String cancelButton = SharedStrings.cancelButton;

  // Dashboard
  static const String levelUpAchieved = SharedStrings.levelUpAchieved;

  // Level-up share card (see LevelUpCelebrationOverlay / LevelUpShareCard)
  static const String shareProgressLevelLabel = SharedStrings.shareProgressLevelLabel;
  static const String shareProgressXpTotalLabel = SharedStrings.shareProgressXpTotalLabel;
  static const String shareProgressXpToNextLabel = SharedStrings.shareProgressXpToNextLabel;
  static const String shareProgressLevelUpBadge = SharedStrings.shareProgressLevelUpBadge;
  static const String shareProgressTagline = SharedStrings.shareProgressTagline;
  static const String shareProgressCta = SharedStrings.shareProgressCta;
  static const String shareProgressButton = SharedStrings.shareProgressButton;
  static const String shareProgressContinueButton = SharedStrings.shareProgressContinueButton;
  static const String shareProgressErrorMessage = SharedStrings.shareProgressErrorMessage;
  static const String academyModuleShareTitle = SharedStrings.academyModuleShareTitle;

  // Academy — UI chrome only; curriculum content (module/lesson text) comes
  // from the backend's Academy catalog API, already resolved to the
  // requested language server-side — it's domain content, not generic UI
  // copy, so it never goes through this Translator map.
  static const String academyLevelLabel = SharedStrings.academyLevelLabel;
  static const String academyXpEarnedLabel = SharedStrings.academyXpEarnedLabel;
  static const String academyContinueSectionLabel = SharedStrings.academyContinueSectionLabel;
  static const String academyXpToCompleteLabel = SharedStrings.academyXpToCompleteLabel;
  static const String academyStartLessonButton = SharedStrings.academyStartLessonButton;
  static const String academyModulesSectionLabel = SharedStrings.academyModulesSectionLabel;
  static const String academyLessonsSectionLabel = SharedStrings.academyLessonsSectionLabel;
  static const String academyLessonsProgressLabel = SharedStrings.academyLessonsProgressLabel;
  static const String academyLessonCompleteTitle = SharedStrings.academyLessonCompleteTitle;
  static const String academyXpPill = SharedStrings.academyXpPill;
  static const String academyContinueButton = SharedStrings.academyContinueButton;
  static const String academyConcludeButton = SharedStrings.academyConcludeButton;
  static const String academyBackToAcademyButton = SharedStrings.academyBackToAcademyButton;
  static const String academyModuleStatusCompleted = SharedStrings.academyModuleStatusCompleted;
  static const String academyModuleStatusInProgress = SharedStrings.academyModuleStatusInProgress;
  static const String academyModuleStatusAvailable = SharedStrings.academyModuleStatusAvailable;
  static const String academyModuleStatusLocked = SharedStrings.academyModuleStatusLocked;
  static const String academyModuleStatusComingSoon = SharedStrings.academyModuleStatusComingSoon;
  static const String academyLockedPrerequisiteLabel = SharedStrings.academyLockedPrerequisiteLabel;
  static const String academyMicroExerciseLabel = SharedStrings.academyMicroExerciseLabel;
  static const String academyApplyLabel = SharedStrings.academyApplyLabel;
  static const String academyCorrectFeedbackTitle = SharedStrings.academyCorrectFeedbackTitle;
  static const String academyIncorrectFeedbackTitle = SharedStrings.academyIncorrectFeedbackTitle;
  static const String academyCorrectFeedbackTitle2 = SharedStrings.academyCorrectFeedbackTitle2;
  static const String academyCorrectFeedbackTitle3 = SharedStrings.academyCorrectFeedbackTitle3;
  static const String academyIncorrectFeedbackTitle2 = SharedStrings.academyIncorrectFeedbackTitle2;
  static const String academyIncorrectFeedbackTitle3 = SharedStrings.academyIncorrectFeedbackTitle3;

  // Academy — School layer (journey view, mastery, Knowledge Progress)
  static const String academySchoolsSectionLabel = SharedStrings.academySchoolsSectionLabel;
  static const String academyDomainsSectionLabel = SharedStrings.academyDomainsSectionLabel;
  static const String academyCatalogErrorTitle = SharedStrings.academyCatalogErrorTitle;
  static const String academyCatalogErrorBody = SharedStrings.academyCatalogErrorBody;
  static const String academyMasterySectionLabel = SharedStrings.academyMasterySectionLabel;
  static const String academyMasteryPercentLabel = SharedStrings.academyMasteryPercentLabel;
  static const String academyKnowledgeLevelLabel = SharedStrings.academyKnowledgeLevelLabel;

  // Academy — real Mastery (performance-based, distinct from Progress/completion above)
  static const String academyProgressLabel = SharedStrings.academyProgressLabel;
  static const String academyRealMasteryLabel = SharedStrings.academyRealMasteryLabel;
  static const String masteryTierExploring = SharedStrings.masteryTierExploring;
  static const String masteryTierUnderstanding = SharedStrings.masteryTierUnderstanding;
  static const String masteryTierApplying = SharedStrings.masteryTierApplying;
  static const String masteryTierMastering = SharedStrings.masteryTierMastering;

  // Academy — Recommended For You + Review
  static const String academyRecommendedSectionLabel = SharedStrings.academyRecommendedSectionLabel;
  static const String academyRecommendationContinueReason = SharedStrings.academyRecommendationContinueReason;
  static const String academyRecommendationReviewReason = SharedStrings.academyRecommendationReviewReason;
  static const String academyReviewCardTitle = SharedStrings.academyReviewCardTitle;
  static const String academyReviewCardSubtitle = SharedStrings.academyReviewCardSubtitle;
  static const String academyReviewStartButton = SharedStrings.academyReviewStartButton;
  static const String academyReviewEmptyState = SharedStrings.academyReviewEmptyState;

  // Academy — Financial Lab
  static const String financialLabSectionLabel = SharedStrings.financialLabSectionLabel;
  static const String financialLabTitle = SharedStrings.financialLabTitle;
  static const String financialLabSubtitle = SharedStrings.financialLabSubtitle;
  static const String labCompoundInterestTitle = SharedStrings.labCompoundInterestTitle;
  static const String labCompoundInterestSubtitle = SharedStrings.labCompoundInterestSubtitle;
  static const String labComingSoon = SharedStrings.labComingSoon;

  // Price provenance on a holding row — shown instead of a gain/loss badge
  // when currentPrice is a fallback rather than a real quote (see PriceStatus).
  static const String holdingQuoteUnavailable = 'holdingQuoteUnavailable';
  static const String holdingNotQuoted = 'holdingNotQuoted';
  static const String labInflationTitle = SharedStrings.labInflationTitle;
  static const String labFixedIncomeTitle = SharedStrings.labFixedIncomeTitle;
  static const String labDiversificationTitle = SharedStrings.labDiversificationTitle;
  static const String labPortfolioTitle = SharedStrings.labPortfolioTitle;
  static const String labInitialAmountLabel = SharedStrings.labInitialAmountLabel;
  static const String labMonthlyContributionLabel = SharedStrings.labMonthlyContributionLabel;
  static const String labAnnualReturnLabel = SharedStrings.labAnnualReturnLabel;
  static const String labYearsLabel = SharedStrings.labYearsLabel;
  static const String labFinalValueLabel = SharedStrings.labFinalValueLabel;
  static const String labTotalContributionsLabel = SharedStrings.labTotalContributionsLabel;
  static const String labTotalGrowthLabel = SharedStrings.labTotalGrowthLabel;
  static const String labExplanationIncreaseYears = SharedStrings.labExplanationIncreaseYears;
  static const String labExplanationDecreaseYears = SharedStrings.labExplanationDecreaseYears;
  static const String labExplanationIncreaseReturn = SharedStrings.labExplanationIncreaseReturn;
  static const String labExplanationDecreaseReturn = SharedStrings.labExplanationDecreaseReturn;
  static const String labExplanationInitial = SharedStrings.labExplanationInitial;
  static const String labYearTooltipLabel = SharedStrings.labYearTooltipLabel;
  static const String labDataTableDisclosureTitle = SharedStrings.labDataTableDisclosureTitle;
  static const String labExplanationIncreaseInitial = SharedStrings.labExplanationIncreaseInitial;
  static const String labExplanationDecreaseInitial = SharedStrings.labExplanationDecreaseInitial;
  static const String labExplanationIncreaseContribution = SharedStrings.labExplanationIncreaseContribution;
  static const String labExplanationDecreaseContribution = SharedStrings.labExplanationDecreaseContribution;
  static const String labCompoundInterestIntro = SharedStrings.labCompoundInterestIntro;
  static const String labCompoundInterestInterpretation = SharedStrings.labCompoundInterestInterpretation;
  static const String labCompleteButton = SharedStrings.labCompleteButton;
  static const String labCompletedLabel = SharedStrings.labCompletedLabel;
  static const String labCompoundInterestQuestion = SharedStrings.labCompoundInterestQuestion;
  static const String labCompoundInterestOptionA = SharedStrings.labCompoundInterestOptionA;
  static const String labCompoundInterestOptionB = SharedStrings.labCompoundInterestOptionB;
  static const String labCompoundInterestOptionC = SharedStrings.labCompoundInterestOptionC;
  static const String labCompoundInterestAnswerExplanation = SharedStrings.labCompoundInterestAnswerExplanation;

  // Academy — Financial Lab — Inflation
  static const String labInflationSubtitle = SharedStrings.labInflationSubtitle;
  static const String labInflationRateLabel = SharedStrings.labInflationRateLabel;
  static const String labInflationRealValueLabel = SharedStrings.labInflationRealValueLabel;
  static const String labInflationNominalValueLabel = SharedStrings.labInflationNominalValueLabel;
  static const String labInflationLostPercentLabel = SharedStrings.labInflationLostPercentLabel;
  static const String labInflationBasketMultiplierLabel = SharedStrings.labInflationBasketMultiplierLabel;
  static const String labInflationIntro = SharedStrings.labInflationIntro;
  static const String labInflationInterpretation = SharedStrings.labInflationInterpretation;
  static const String labInflationInvestingConnection = SharedStrings.labInflationInvestingConnection;
  static const String labInflationQuestion = SharedStrings.labInflationQuestion;
  static const String labInflationOptionA = SharedStrings.labInflationOptionA;
  static const String labInflationOptionB = SharedStrings.labInflationOptionB;
  static const String labInflationOptionC = SharedStrings.labInflationOptionC;
  static const String labInflationAnswerExplanation = SharedStrings.labInflationAnswerExplanation;

  // Academy — Financial Lab — Fixed Income
  static const String labFixedIncomeSubtitle = SharedStrings.labFixedIncomeSubtitle;
  static const String labFixedIncomePrincipalLabel = SharedStrings.labFixedIncomePrincipalLabel;
  static const String labFixedIncomeInterestLabel = SharedStrings.labFixedIncomeInterestLabel;
  static const String labFixedIncomeNominalRateLabel = SharedStrings.labFixedIncomeNominalRateLabel;
  static const String labFixedIncomeEffectiveRateLabel = SharedStrings.labFixedIncomeEffectiveRateLabel;
  static const String labFixedIncomeGrossDisclaimer = SharedStrings.labFixedIncomeGrossDisclaimer;
  static const String labFixedIncomeIntro = SharedStrings.labFixedIncomeIntro;
  static const String labFixedIncomeInterpretation = SharedStrings.labFixedIncomeInterpretation;
  static const String labFixedIncomeQuestion = SharedStrings.labFixedIncomeQuestion;
  static const String labFixedIncomeOptionA = SharedStrings.labFixedIncomeOptionA;
  static const String labFixedIncomeOptionB = SharedStrings.labFixedIncomeOptionB;
  static const String labFixedIncomeOptionC = SharedStrings.labFixedIncomeOptionC;
  static const String labFixedIncomeAnswerExplanation = SharedStrings.labFixedIncomeAnswerExplanation;

  // Academy — Financial Lab — investment category labels (shared by
  // Diversification and Portfolio)
  static const String labInvestmentTypeStocks = SharedStrings.labInvestmentTypeStocks;
  static const String labInvestmentTypeFixedIncome = SharedStrings.labInvestmentTypeFixedIncome;
  static const String labInvestmentTypeRealEstate = SharedStrings.labInvestmentTypeRealEstate;
  static const String labInvestmentTypeCrypto = SharedStrings.labInvestmentTypeCrypto;
  static const String labInvestmentTypeFunds = SharedStrings.labInvestmentTypeFunds;
  static const String labInvestmentTypeOthers = SharedStrings.labInvestmentTypeOthers;
  static const String labAllocationTotalLabel = SharedStrings.labAllocationTotalLabel;
  static const String labAllocationHint = SharedStrings.labAllocationHint;

  // Academy — Financial Lab — Diversification
  static const String labDiversificationSubtitle = SharedStrings.labDiversificationSubtitle;
  static const String labDiversificationScoreLabel = SharedStrings.labDiversificationScoreLabel;
  static const String labDiversificationEffectiveAssetsLabel = SharedStrings.labDiversificationEffectiveAssetsLabel;
  static const String labDiversificationConcentrationLabel = SharedStrings.labDiversificationConcentrationLabel;
  static const String labDiversificationIntro = SharedStrings.labDiversificationIntro;
  static const String labDiversificationInterpretation = SharedStrings.labDiversificationInterpretation;
  static const String labDiversificationConcentrationShockButton =
      SharedStrings.labDiversificationConcentrationShockButton;
  static const String labDiversificationMarketShockButton = SharedStrings.labDiversificationMarketShockButton;
  static const String labDiversificationConcentrationShockResult =
      SharedStrings.labDiversificationConcentrationShockResult;
  static const String labDiversificationMarketShockResult = SharedStrings.labDiversificationMarketShockResult;
  static const String labDiversificationSafetyDisclaimer = SharedStrings.labDiversificationSafetyDisclaimer;
  static const String labDiversificationQuestion = SharedStrings.labDiversificationQuestion;
  static const String labDiversificationOptionA = SharedStrings.labDiversificationOptionA;
  static const String labDiversificationOptionB = SharedStrings.labDiversificationOptionB;
  static const String labDiversificationOptionC = SharedStrings.labDiversificationOptionC;
  static const String labDiversificationAnswerExplanation = SharedStrings.labDiversificationAnswerExplanation;

  // Academy — Financial Lab — Portfolio
  static const String labPortfolioSubtitle = SharedStrings.labPortfolioSubtitle;
  static const String labPortfolioTotalAmountLabel = SharedStrings.labPortfolioTotalAmountLabel;
  static const String labPortfolioNewValueLabel = SharedStrings.labPortfolioNewValueLabel;
  static const String labPortfolioDeltaLabel = SharedStrings.labPortfolioDeltaLabel;
  static const String labPortfolioIntro = SharedStrings.labPortfolioIntro;
  static const String labPortfolioSandboxDisclaimer = SharedStrings.labPortfolioSandboxDisclaimer;
  static const String labPortfolioForecastDisclaimer = SharedStrings.labPortfolioForecastDisclaimer;
  static const String labPortfolioScenarioEquitiesDown15 = SharedStrings.labPortfolioScenarioEquitiesDown15;
  static const String labPortfolioScenarioLargestPositionDown20 =
      SharedStrings.labPortfolioScenarioLargestPositionDown20;
  static const String labPortfolioScenarioBroadMarketDown10 = SharedStrings.labPortfolioScenarioBroadMarketDown10;
  static const String labPortfolioScenarioFixedIncomeUp5 = SharedStrings.labPortfolioScenarioFixedIncomeUp5;
  static const String labPortfolioScenarioResult = SharedStrings.labPortfolioScenarioResult;
  static const String labPortfolioQuestion = SharedStrings.labPortfolioQuestion;
  static const String labPortfolioOptionA = SharedStrings.labPortfolioOptionA;
  static const String labPortfolioOptionB = SharedStrings.labPortfolioOptionB;
  static const String labPortfolioOptionC = SharedStrings.labPortfolioOptionC;
  static const String labPortfolioAnswerExplanation = SharedStrings.labPortfolioAnswerExplanation;

  // Dashboard — AppBar / bottom navigation shell
  static const String appBarPlayerNamedGreeting = SharedStrings.appBarPlayerNamedGreeting;
  static const String appBarPlayerGenericGreeting = SharedStrings.appBarPlayerGenericGreeting;
  static const String profileTooltip = SharedStrings.profileTooltip;
  static const String notificationsTooltip = SharedStrings.notificationsTooltip;
  static const String logoutTooltip = SharedStrings.logoutTooltip;
  static const String navHome = SharedStrings.navHome;
  static const String navWallet = SharedStrings.navWallet;
  static const String navPassiveIncome = SharedStrings.navPassiveIncome;
  static const String navAcademy = SharedStrings.navAcademy;
  static const String navMentor = SharedStrings.navMentor;

  // Wallet's "Visão Geral" overview screen (real-portfolio dashboard,
  // replaces the old learning-first Home) and its public Academy bridge —
  // see docs/ECOSYSTEM.md's Stage 5 note. Never an in-app tab switch: Wallet
  // and Academy are separate apps.
  static const String overviewNoInsightsYet = 'overviewNoInsightsYet';
  static const String academyBridgeCtaLabel = 'academyBridgeCtaLabel';
  static const String academyBridgeComingSoon = 'academyBridgeComingSoon';

  // Home redesign — learning-first hierarchy (docs/PRODUCT_VISION.md §8)
  static const String homeContinueLearningEyebrow = SharedStrings.homeContinueLearningEyebrow;
  static const String homeContinueLearningCta = SharedStrings.homeContinueLearningCta;
  static const String homeAllLessonsCompleteTitle = SharedStrings.homeAllLessonsCompleteTitle;
  static const String homeAllLessonsCompleteBody = SharedStrings.homeAllLessonsCompleteBody;
  static const String homeExploreAcademyCta = SharedStrings.homeExploreAcademyCta;
  static const String homeLevelProgressLabel = SharedStrings.homeLevelProgressLabel;
  static const String homeNextEvolutionLabel = SharedStrings.homeNextEvolutionLabel;
  static const String homeMaxEvolutionLabel = SharedStrings.homeMaxEvolutionLabel;
  static const String homeKnowledgeMapLabel = SharedStrings.homeKnowledgeMapLabel;
  static const String homeViewFullAcademyCta = SharedStrings.homeViewFullAcademyCta;
  static const String homePortfolioBridgeLabel = SharedStrings.homePortfolioBridgeLabel;
  static const String homePortfolioBridgeApplyMessage = SharedStrings.homePortfolioBridgeApplyMessage;
  static const String homeViewPortfolioCta = SharedStrings.homeViewPortfolioCta;
  static const String homeAnswerInvestorProfileLink = SharedStrings.homeAnswerInvestorProfileLink;
  static const String homeMissionAlmostDoneEyebrow = SharedStrings.homeMissionAlmostDoneEyebrow;
  static const String homeMissionAlmostDoneBody = SharedStrings.homeMissionAlmostDoneBody;

  // Level tiers — motivational milestone names, never a competence
  // certification (docs/PRODUCT_VISION.md §9; docs/FEATURES.md "Levels").
  static const String levelTierBeginner = SharedStrings.levelTierBeginner;
  static const String levelTierLearner = SharedStrings.levelTierLearner;
  static const String levelTierExplorer = SharedStrings.levelTierExplorer;
  static const String levelTierInvestor = SharedStrings.levelTierInvestor;
  static const String levelTierAnalyst = SharedStrings.levelTierAnalyst;
  static const String levelTierStrategist = SharedStrings.levelTierStrategist;
  static const String levelTierSpecialist = SharedStrings.levelTierSpecialist;

  // Knowledge Progress tiers — curriculum-completion track, deliberately
  // distinct from the Game Level tiers above (docs/PRODUCT_VISION.md §9).
  static const String knowledgeLevelAbsoluteBeginner = SharedStrings.knowledgeLevelAbsoluteBeginner;
  static const String knowledgeLevelFinancialApprentice = SharedStrings.knowledgeLevelFinancialApprentice;
  static const String knowledgeLevelFinancialOrganizer = SharedStrings.knowledgeLevelFinancialOrganizer;
  static const String knowledgeLevelFinancialProtector = SharedStrings.knowledgeLevelFinancialProtector;
  static const String knowledgeLevelBeginnerInvestor = SharedStrings.knowledgeLevelBeginnerInvestor;
  static const String knowledgeLevelInvestor = SharedStrings.knowledgeLevelInvestor;
  static const String knowledgeLevelAnalyst = SharedStrings.knowledgeLevelAnalyst;
  static const String knowledgeLevelWealthBuilder = SharedStrings.knowledgeLevelWealthBuilder;
  static const String knowledgeLevelFinancialStrategist = SharedStrings.knowledgeLevelFinancialStrategist;
  static const String knowledgeLevelFinancialMaster = SharedStrings.knowledgeLevelFinancialMaster;

  // Persistent pet companion — global header, speech bubble, interaction sheet
  static const String companionHeaderTooltip = SharedStrings.companionHeaderTooltip;
  static const String companionDismissTooltip = SharedStrings.companionDismissTooltip;
  static const String companionInteractionTitle = SharedStrings.companionInteractionTitle;
  static const String companionInteractionSubtitle = SharedStrings.companionInteractionSubtitle;
  static const String companionInteractionLearn = SharedStrings.companionInteractionLearn;
  static const String companionInteractionPortfolio = SharedStrings.companionInteractionPortfolio;
  static const String companionInteractionProgress = SharedStrings.companionInteractionProgress;
  static const String companionActionContinue = SharedStrings.companionActionContinue;
  static const String companionActionViewPortfolio = SharedStrings.companionActionViewPortfolio;
  static const String companionActionViewProgress = SharedStrings.companionActionViewProgress;
  static const String companionHomeXpToNextLevel = SharedStrings.companionHomeXpToNextLevel;
  static const String companionAcademyContinueLesson = SharedStrings.companionAcademyContinueLesson;
  static const String companionAcademyReviewDue = SharedStrings.companionAcademyReviewDue;
  static const String companionPortfolioDiversified = SharedStrings.companionPortfolioDiversified;
  static const String companionMentorNudge = SharedStrings.companionMentorNudge;
  static const String companionProfileSummary = SharedStrings.companionProfileSummary;
  static const String companionEventLessonCompleted = SharedStrings.companionEventLessonCompleted;
  static const String companionEventXpGained = SharedStrings.companionEventXpGained;
  static const String companionEventLevelUp = SharedStrings.companionEventLevelUp;
  static const String companionEventAchievementUnlocked = SharedStrings.companionEventAchievementUnlocked;
  static const String companionEventEvolved = SharedStrings.companionEventEvolved;
  static const String companionEventDifficultyDetected = SharedStrings.companionEventDifficultyDetected;
  static const String companionEventSchoolMastered = SharedStrings.companionEventSchoolMastered;
  static const String companionEventFirstInvestment = SharedStrings.companionEventFirstInvestment;
  static const String companionEventHighConcentration = SharedStrings.companionEventHighConcentration;
  static const String companionPortfolioActivationNudge = SharedStrings.companionPortfolioActivationNudge;
  static const String companionInvestorStatusYes = SharedStrings.companionInvestorStatusYes;
  static const String companionInvestorStatusNo = SharedStrings.companionInvestorStatusNo;
  static const String companionActionUnderstand = SharedStrings.companionActionUnderstand;
  static const String companionHomeMotivation1 = SharedStrings.companionHomeMotivation1;
  static const String companionHomeMotivation2 = SharedStrings.companionHomeMotivation2;
  static const String companionHomeMotivation3 = SharedStrings.companionHomeMotivation3;
  static const String companionHomeMotivation4 = SharedStrings.companionHomeMotivation4;
  static const String companionHomeMotivation5 = SharedStrings.companionHomeMotivation5;
  static const String companionHomeReturnGreeting1 = SharedStrings.companionHomeReturnGreeting1;
  static const String companionHomeReturnGreeting2 = SharedStrings.companionHomeReturnGreeting2;
  static const String companionHomeMissionAlmostDone = SharedStrings.companionHomeMissionAlmostDone;
  static const String companionEventMissionCompleted = SharedStrings.companionEventMissionCompleted;
  static const String companionEventLabSimulatorCompleted = SharedStrings.companionEventLabSimulatorCompleted;

  // Portfolio — wealth/proventos evolution cards (chart legend labels)
  static const String wealthLegendPatrimony = SharedStrings.wealthLegendPatrimony;
  static const String wealthLegendInvested = SharedStrings.wealthLegendInvested;
  static const String wealthLegendAppliedValue = SharedStrings.wealthLegendAppliedValue;
  static const String wealthLegendCapitalGain = SharedStrings.wealthLegendCapitalGain;
  static const String proventosLegendReceived = SharedStrings.proventosLegendReceived;
  static const String proventosLegendExpected = SharedStrings.proventosLegendExpected;

  // Portfolio — shared empty/error states
  static const String noAssetsRegisteredYet = SharedStrings.noAssetsRegisteredYet;
  static const String retryButtonLabel = SharedStrings.retryButtonLabel;

  // Generic fallback error copy — used by friendlyErrorMessage() wherever a
  // caught error has no more specific translated message of its own.
  static const String errorNoConnectionMessage = SharedStrings.errorNoConnectionMessage;
  static const String errorUnexpectedMessage = SharedStrings.errorUnexpectedMessage;

  // Mentor
  static const String mentorNewChatTooltip = SharedStrings.mentorNewChatTooltip;
  static const String mentorHistoryTooltip = SharedStrings.mentorHistoryTooltip;
  static const String mentorConversationHistoryTitle = SharedStrings.mentorConversationHistoryTitle;
  static const String mentorNoConversationsTitle = SharedStrings.mentorNoConversationsTitle;
  static const String mentorNoConversationsSubtitle = SharedStrings.mentorNoConversationsSubtitle;
  static const String mentorConversationsLoadError = SharedStrings.mentorConversationsLoadError;
  static const String mentorRenameConversationTitle = SharedStrings.mentorRenameConversationTitle;
  static const String mentorRenameConversationHint = SharedStrings.mentorRenameConversationHint;
  static const String mentorRenameConversationSave = SharedStrings.mentorRenameConversationSave;
  static const String mentorRenameConversationFailed = SharedStrings.mentorRenameConversationFailed;
  static const String mentorDeleteConversationTitle = SharedStrings.mentorDeleteConversationTitle;
  static const String mentorDeleteConversationConfirm = SharedStrings.mentorDeleteConversationConfirm;
  static const String mentorDeleteConversationButton = SharedStrings.mentorDeleteConversationButton;
  static const String mentorDeleteConversationFailed = SharedStrings.mentorDeleteConversationFailed;

  // Investment configuration
  static const String initialPortfolioTitle = SharedStrings.initialPortfolioTitle;

  // Portfolio summary card (investment feature)
  static const String portfolioCardTitle = SharedStrings.portfolioCardTitle;

  // Profile
  static const String profileTitle = SharedStrings.profileTitle;
  static const String profileCommanderTitle = SharedStrings.profileCommanderTitle;
  static const String profileAchievementsLabel = SharedStrings.profileAchievementsLabel;
  static const String profileAchievementsComingSoonBody = SharedStrings.profileAchievementsComingSoonBody;
  static const String profileSettingsHint = SharedStrings.profileSettingsHint;

  // Investor risk-profile questionnaire (distinct from the onboarding
  // wizard's financial-goal step — see FinancialGoalScreen).
  static const String investorProfileScreenTitle = SharedStrings.investorProfileScreenTitle;
  static const String investorProfileScreenSubtitle = SharedStrings.investorProfileScreenSubtitle;
  static const String investorProfileClearAnswersButton = SharedStrings.investorProfileClearAnswersButton;
  static const String investorProfileClearAnswers = SharedStrings.investorProfileClearAnswers;

  // Asset details — pet teacher widget
  static const String petTeacherAskMentor = SharedStrings.petTeacherAskMentor;
  static const String petTeacherOwnedGreeting = SharedStrings.petTeacherOwnedGreeting;
  static const String petTeacherNotOwnedGreeting = SharedStrings.petTeacherNotOwnedGreeting;
}
