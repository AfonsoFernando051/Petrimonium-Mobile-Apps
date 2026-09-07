/// Flutter-level infrastructure shared by every Petrimonium application.
///
/// What belongs here: things that are the same because the *platform and the
/// backend* are the same - environment configuration, the authenticated HTTP
/// client and its refresh/session handling, and small pure utilities.
///
/// What must never appear here: product business rules. Account, XP, Pet
/// evolution, Mentor context and every financial rule are owned by the
/// backend's domain model. Flutter may carry DTOs, clients, presentation
/// models and caching for them; it must not quietly become their source of
/// truth. Nor does this package hold UI - that is `petrimonium_ui`.
library;

export 'src/config/petrimonium_environment.dart';
export 'src/network/api_client.dart';
export 'src/network/api_error_parser.dart';
export 'src/util/formatters.dart';
export 'src/util/password_policy.dart';
export 'src/util/user_scoped_prefs.dart';
