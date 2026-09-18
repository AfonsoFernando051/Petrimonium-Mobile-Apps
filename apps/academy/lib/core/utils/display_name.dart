/// There is no user display-name field anywhere yet (backend or client) —
/// only email. Derives a graceful, honest stand-in from it rather than
/// fabricating one; the real fix is a backend profile-name field. Returns
/// `null` when [email] itself is missing/empty, so callers can fall back to
/// no name shown at all instead of a broken empty string.
String? deriveDisplayNameFromEmail(String? email) {
  if (email == null || email.isEmpty) return null;
  final localPart = email.split('@').first;
  final firstToken = localPart.split(RegExp(r'[._-]')).first;
  if (firstToken.isEmpty) return null;
  return firstToken[0].toUpperCase() + firstToken.substring(1);
}
