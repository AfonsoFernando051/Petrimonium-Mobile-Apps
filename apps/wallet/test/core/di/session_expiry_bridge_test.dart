import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_wallet/core/events/app_event.dart';
import 'package:petrimonium_wallet/core/events/app_event_bus.dart';

/// The shared ApiClient reports session expiry through an *optional*
/// callback, so a missing wire-up would not fail analysis or any test in
/// petrimonium_flutter_core - the user would just silently stop being sent
/// back to the login screen when their refresh token dies. This test pins
/// the app side of that contract.
void main() {
  test('the DI session-expiry bridge emits SessionExpiredEvent on the app bus', () async {
    final events = <AppEvent>[];
    final subscription = AppEventBus.instance.stream.listen(events.add);

    DI.notifySessionExpired();
    await Future<void>.delayed(Duration.zero);

    expect(events, contains(isA<SessionExpiredEvent>()));

    await subscription.cancel();
  });
}
