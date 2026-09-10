abstract final class ApiConfig {
  static const String appContext = 'health';

  // O Client ID Web do Google Cloud, passado ao GoogleSignIn como
  // serverClientId para o ID token sair com a audience que o backend
  // verifica em `google.oauth.client-ids`. É o mesmo valor da Wallet e da
  // Academy — o client é do backend, não de cada app. Vazio por omissão:
  //   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
  static const String googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  static const String healthBase = '/api/v1/health';
}
