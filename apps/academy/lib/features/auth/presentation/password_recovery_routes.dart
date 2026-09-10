import 'package:flutter/material.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/di/dependency_injection.dart';
import 'package:petrimonium_academy/core/utils/friendly_error_message.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/auth/presentation/widgets/login_background.dart';

/// Builds the shared password-recovery screens with this product's wiring:
/// its auth repository, its backdrop and its wording.
///
/// The copy is resolved here, at push time, which is when each screen is
/// built — the same moment the app-local versions used to resolve it.
ForgotPasswordScreen buildForgotPasswordScreen(BuildContext context) => ForgotPasswordScreen(
  background: const LoginBackground(),
  onRequestReset: DI.authRepository.requestPasswordReset,
  errorMessageBuilder: friendlyErrorMessage,
  onGoToReset: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => buildResetPasswordScreen())),
  copy: (
    title: Translator.translate(AppStrings.forgotPasswordTitle),
    subtitle: Translator.translate(AppStrings.forgotPasswordSubtitle),
    emailHint: Translator.translate(AppStrings.forgotPasswordEmailHint),
    sendLabel: Translator.translate(AppStrings.forgotPasswordSendButton),
    confirmationMessage: Translator.translate(AppStrings.forgotPasswordConfirmationMessage),
    haveCodeLabel: Translator.translate(AppStrings.forgotPasswordHaveCodeLink),
  ),
);

ResetPasswordScreen buildResetPasswordScreen() => ResetPasswordScreen(
  background: const LoginBackground(),
  onResetPassword: DI.authRepository.resetPassword,
  errorMessageBuilder: friendlyErrorMessage,
  copy: (
    title: Translator.translate(AppStrings.resetPasswordTitle),
    subtitle: Translator.translate(AppStrings.resetPasswordSubtitle),
    tokenHint: Translator.translate(AppStrings.resetPasswordTokenHint),
    newPasswordHint: Translator.translate(AppStrings.resetPasswordNewPasswordHint),
    confirmPasswordHint: Translator.translate(AppStrings.confirmPasswordHint),
    submitLabel: Translator.translate(AppStrings.resetPasswordSubmitButton),
    successMessage: Translator.translate(AppStrings.resetPasswordSuccessMessage),
    mismatchError: Translator.translate(AppStrings.resetPasswordMismatchError),
    fieldsRequiredError: Translator.translate(AppStrings.resetPasswordFieldsRequiredError),
  ),
);
