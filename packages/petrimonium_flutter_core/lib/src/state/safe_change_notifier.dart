import 'package:flutter/foundation.dart';

/// A `ChangeNotifier` mixin that guards against the recurring bug where a
/// controller's owning screen disposes it while an unawaited async task it
/// kicked off (typically from `initState`, e.g. `controller.loadAll()`
/// without an `await`) is still in flight. When that task later completes
/// and calls `notifyListeners()`, plain `ChangeNotifier` throws
/// "A ChangeNotifier was used after being disposed" — a crash driven purely
/// by timing (how fast the network responds vs. how fast the user navigates
/// away), not by anything wrong with the data.
///
/// Mix this in and replace the `notifyListeners()` calls that follow
/// awaited/async work with [notifySafely] (also available as
/// [safeNotifyListeners] for readability at call sites that don't already
/// say "safely"). Synchronous mutations that notify before any `await` don't
/// need it — the controller can't have been disposed yet at that point in
/// the same synchronous call.
mixin SafeChangeNotifier on ChangeNotifier {
  bool _disposed = false;

  /// Whether [dispose] has already run on this instance.
  bool get disposed => _disposed;

  /// Calls `notifyListeners()` only if this instance hasn't been disposed
  /// yet — a no-op otherwise, instead of throwing.
  void notifySafely() {
    if (!_disposed) notifyListeners();
  }

  /// Alias for [notifySafely], for call sites that read better as "safely
  /// notify listeners" than "notify safely".
  void safeNotifyListeners() => notifySafely();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
