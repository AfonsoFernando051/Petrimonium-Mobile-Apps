/// Petrimonium's shared visual foundation.
///
/// What belongs here: design tokens, the theme builder, and presentation-only
/// widgets that Academy, Wallet and Health would all want fixed at once.
///
/// What must never appear here: a product name, a product route, a product
/// business rule, a string catalog, or a `switch` on which app is running.
/// Everything product-specific arrives as configuration - colors through
/// [PetrimoniumTheme.build], copy through widget parameters, behavior through
/// callbacks.
library;

export 'src/navigation/fade_route.dart';
export 'src/theme/petrimonium_theme.dart';
export 'src/theme/theme_controller.dart';
export 'src/tokens/app_color_tokens.dart';
export 'src/tokens/app_motion.dart';
export 'src/tokens/app_radii.dart';
export 'src/tokens/app_spacing.dart';
export 'src/tokens/app_text_styles.dart';
export 'src/tokens/brand_accents.dart';
export 'src/widgets/app_loading_indicator.dart';
export 'src/widgets/appearance_option_card.dart';
export 'src/widgets/chart_legend.dart';
export 'src/widgets/comic_bubble_painter.dart';
export 'src/widgets/confirm_logout_dialog.dart';
export 'src/widgets/custom_text_field.dart';
export 'src/widgets/dashed_outline.dart';
export 'src/widgets/empty_state_view.dart';
export 'src/widgets/error_banner.dart';
export 'src/widgets/error_state_view.dart';
export 'src/widgets/field_label.dart';
export 'src/widgets/forgot_password_button.dart';
export 'src/widgets/game_button.dart';
export 'src/widgets/game_snack.dart';
export 'src/widgets/glass_card.dart';
export 'src/widgets/google_signin_button.dart';
export 'src/widgets/mentor_input_bar.dart';
export 'src/widgets/option_pill.dart';
export 'src/widgets/option_row.dart';
export 'src/widgets/or_divider.dart';
export 'src/widgets/settings_toggle_card.dart';
export 'src/widgets/shared_account_notice.dart';
export 'src/widgets/suggested_prompt_chip.dart';
export 'src/widgets/tooltip_summary.dart';
export 'src/widgets/typing_indicator.dart';
export 'src/widgets/unavailable_badge.dart';
