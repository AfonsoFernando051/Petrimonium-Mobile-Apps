import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/di/dependency_injection.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/core/widgets/cosmic_background.dart';

/// Builds the shared conversation-history screen with this product's wiring:
/// its repository, its backdrop and its wording.
///
/// The copy is resolved here, at push time, which is when the screen is built
/// — the same moment the app-local version used to resolve it.
ConversationListScreen buildConversationListScreen() => ConversationListScreen(
  store: DI.mentorChatRepository,
  background: (child) => CosmicBackground(child: child),
  copy: (
    historyTitle: Translator.translate(AppStrings.mentorConversationHistoryTitle),
    newChatLabel: Translator.translate(AppStrings.mentorNewChatTooltip),
    emptyTitle: Translator.translate(AppStrings.mentorNoConversationsTitle),
    emptySubtitle: Translator.translate(AppStrings.mentorNoConversationsSubtitle),
    loadError: Translator.translate(AppStrings.mentorConversationsLoadError),
    retryLabel: Translator.translate(AppStrings.retryButtonLabel),
    renameTitle: Translator.translate(AppStrings.mentorRenameConversationTitle),
    renameHint: Translator.translate(AppStrings.mentorRenameConversationHint),
    renameSave: Translator.translate(AppStrings.mentorRenameConversationSave),
    renameFailed: Translator.translate(AppStrings.mentorRenameConversationFailed),
    deleteTitle: Translator.translate(AppStrings.mentorDeleteConversationTitle),
    deleteConfirm: Translator.translate(AppStrings.mentorDeleteConversationConfirm),
    deleteButton: Translator.translate(AppStrings.mentorDeleteConversationButton),
    deleteFailed: Translator.translate(AppStrings.mentorDeleteConversationFailed),
    cancelLabel: Translator.translate(AppStrings.cancelButton),
  ),
);
