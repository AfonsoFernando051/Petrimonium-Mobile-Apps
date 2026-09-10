import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import 'package:petrimonium_wallet/core/utils/translator.dart';

/// Maps a caught error into copy that's safe and clear to show a user —
/// never the raw `Exception: ...` text, and something more useful than that
/// for the most common failure (no connectivity). Always returns text in the
/// user's currently selected language (see [Translator]).
///
/// The classification lives in [friendlyErrorCopy] so both products agree on
/// what counts as a connectivity failure; only the wording is resolved here.
String friendlyErrorMessage(Object error) {
  final copy = friendlyErrorCopy(error);
  final key = copy.key;
  return key == null ? copy.text! : Translator.translate(key);
}
