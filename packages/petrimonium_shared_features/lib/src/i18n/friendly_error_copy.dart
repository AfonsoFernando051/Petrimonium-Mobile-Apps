import 'dart:io';

import 'shared_strings.dart';

/// What to show the user for a caught error: either a copy [key] to translate,
/// or literal [text] that is already safe to display as-is.
///
/// Exactly one of the two is non-null.
typedef ErrorCopy = ({String? key, String? text});

/// Classifies a caught error into user-facing copy.
///
/// The classification is an ecosystem rule, not product voice: whether a
/// failure counts as "no connectivity" must not depend on which app caught it,
/// and neither must the guarantee that a raw `Exception: ...` never reaches a
/// user. Each product still supplies the wording for the keys returned here.
ErrorCopy friendlyErrorCopy(Object error) {
  if (error is SocketException) {
    return (key: SharedStrings.errorNoConnectionMessage, text: null);
  }

  final text = error.toString().replaceFirst('Exception: ', '').trim();
  final lower = text.toLowerCase();
  if (lower.contains('socketexception') || lower.contains('connection') || lower.contains('network')) {
    return (key: SharedStrings.errorNoConnectionMessage, text: null);
  }

  return text.isEmpty ? (key: SharedStrings.errorUnexpectedMessage, text: null) : (key: null, text: text);
}
