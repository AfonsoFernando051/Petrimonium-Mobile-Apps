import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';

class _FakeAsyncController extends ChangeNotifier with SafeChangeNotifier {
  void notifyDirectly() => notifyListeners();
  void notifyThroughSafeHelper() => notifySafely();
}

void main() {
  group('SafeChangeNotifier', () {
    test('disposed is false before dispose() is called', () {
      final controller = _FakeAsyncController();

      expect(controller.disposed, isFalse);

      controller.dispose();
    });

    test('disposed is true after dispose() is called', () {
      final controller = _FakeAsyncController();

      controller.dispose();

      expect(controller.disposed, isTrue);
    });

    test('notifySafely() does not throw after dispose() — the bug plain notifyListeners() would hit', () {
      final controller = _FakeAsyncController();
      controller.dispose();

      // A fire-and-forget async task (e.g. a repository call kicked off from
      // initState and never awaited) can still be running after its owning
      // screen — and therefore this controller — has been disposed. Calling
      // notifyListeners() directly in that situation throws
      // "A ChangeNotifier was used after being disposed" in debug/test
      // builds; notifySafely() must silently no-op instead.
      expect(controller.notifyThroughSafeHelper, returnsNormally);
    });

    test('plain notifyListeners() does throw after dispose(), proving the mixin is not a no-op by accident', () {
      final controller = _FakeAsyncController();
      controller.dispose();

      expect(controller.notifyDirectly, throwsFlutterError);
    });

    test('notifySafely() still notifies listeners normally before dispose()', () {
      final controller = _FakeAsyncController();
      var callCount = 0;
      controller.addListener(() => callCount++);

      controller.notifyThroughSafeHelper();

      expect(callCount, 1);
      controller.dispose();
    });
  });
}
