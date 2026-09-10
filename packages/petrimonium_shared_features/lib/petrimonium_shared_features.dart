/// Features that genuinely belong to the whole Petrimonium ecosystem rather
/// than to one product.
///
/// The bar for entry is the question from the architecture doc: if we fix or
/// improve this, should Academy, Wallet and Health all receive the change?
/// Gamification clears it - global XP and global level are one number per
/// account, produced by one backend ledger, and a bug in the level maths is a
/// bug in every product at once.
///
/// What stays out: anything whose authoritative rules live in the backend
/// domain (financial calculations, Academy progression, Health scoring), and
/// anything that only looks shared because Academy and Wallet were forked
/// from the same codebase — coincidental similarity, not one thing. Auth UI
/// clears that bar too, but for the opposite reason gamification does:
/// verified byte-for-byte identical (or a single cosmetic line apart) before
/// extraction, with every difference between products being copy, an accent
/// color or a callback — see `docs/MOBILE_ARCHITECTURE.md`.
library;

export 'src/academy/data/academy_catalog_repository.dart';
export 'src/academy/data/academy_catalog_snapshot.dart';
export 'src/academy/data/academy_progress_local_repository.dart';
export 'src/academy/domain/academy_domain.dart';
export 'src/academy/domain/academy_module.dart';
export 'src/academy/domain/lesson.dart';
export 'src/academy/domain/lesson_step.dart';
export 'src/academy/domain/school.dart';
export 'src/academy/presentation/academy_icon_registry.dart';
export 'src/auth/presentation/forgot_password_screen.dart';
export 'src/auth/presentation/login_form.dart';
export 'src/auth/presentation/reset_password_screen.dart';
export 'src/auth/presentation/signup_form.dart';
export 'src/gamification/data/gamification_remote_datasource.dart';
export 'src/gamification/data/gamification_repository.dart';
export 'src/gamification/domain/gamification_summary.dart';
export 'src/gamification/domain/level_calculator.dart';
export 'src/gamification/domain/level_tier.dart';
export 'src/gamification/domain/level_tier_copy.dart';
export 'src/gamification/domain/player_level.dart';
export 'src/i18n/friendly_error_copy.dart';
export 'src/i18n/shared_copy.dart';
export 'src/i18n/shared_strings.dart';
export 'src/mentor/domain/conversation_store.dart';
export 'src/mentor/domain/conversation_summary.dart';
export 'src/mentor/presentation/conversation_list_controller.dart';
export 'src/mentor/presentation/conversation_list_screen.dart';
export 'src/mentor/presentation/conversation_list_tile.dart';
export 'src/onboarding/data/onboarding_status_model.dart';
export 'src/onboarding/data/option_model.dart';
export 'src/onboarding/data/question_model.dart';
export 'src/pet/data/pet_companion_preferences_repository.dart';
export 'src/pet/domain/accessory_type.dart';
export 'src/pet/domain/mascot_repository.dart';
export 'src/pet/domain/pet_accessory.dart';
export 'src/pet/domain/pet_accessory_id.dart';
export 'src/pet/domain/pet_animation_state.dart';
export 'src/pet/domain/pet_evolution_rule.dart';
export 'src/pet/domain/pet_evolution_stage.dart';
export 'src/pet/domain/pet_profile.dart';
export 'src/pet/domain/pet_specie_enum.dart';
export 'src/pet/presentation/pet_context.dart';
export 'src/pet/presentation/pet_speech_bubble_anchor.dart';
export 'src/portfolio/data/achievements_local_repository.dart';
export 'src/portfolio/data/achievements_remote_datasource.dart';
export 'src/portfolio/data/achievements_repository.dart';
export 'src/portfolio/data/missions_remote_datasource.dart';
export 'src/portfolio/data/missions_repository.dart';
export 'src/portfolio/data/portfolio_remote_datasource.dart';
export 'src/portfolio/data/portfolio_repository.dart';
export 'src/portfolio/domain/achievement_evaluation_result.dart';
export 'src/portfolio/domain/achievement_rules.dart';
export 'src/portfolio/domain/allocation_slice.dart';
export 'src/portfolio/domain/dividend_event.dart';
export 'src/portfolio/domain/history_point.dart';
export 'src/portfolio/domain/history_range.dart';
export 'src/portfolio/domain/holding.dart';
export 'src/portfolio/domain/investment_lot.dart';
export 'src/portfolio/domain/investment_type_enum.dart';
export 'src/portfolio/domain/investment_type_rules.dart';
export 'src/portfolio/domain/mission_status.dart';
export 'src/portfolio/domain/passive_income_estimate.dart';
export 'src/portfolio/domain/passive_income_estimator.dart';
export 'src/portfolio/domain/portfolio_health.dart';
export 'src/portfolio/domain/portfolio_health_calculator.dart';
export 'src/portfolio/domain/portfolio_stats.dart';
export 'src/portfolio/domain/portfolio_summary.dart';
export 'src/portfolio/domain/price_status.dart';
export 'src/portfolio/domain/wealth_history_calculator.dart';
export 'src/settings/data/settings_remote_datasource.dart';
export 'src/settings/presentation/account_section.dart';
export 'src/settings/presentation/appearance_section.dart';
export 'src/settings/presentation/companion_section.dart';
export 'src/settings/presentation/country_section.dart';
export 'src/settings/presentation/language_section.dart';
export 'src/settings/presentation/notifications_section.dart';
export 'src/settings/presentation/privacy_section.dart';
