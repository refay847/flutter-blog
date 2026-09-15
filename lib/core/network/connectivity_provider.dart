// lib/core/network/connectivity_provider.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits the current connectivity status immediately, then keeps
/// streaming updates whenever it changes.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  final initial = await connectivity.checkConnectivity();
  yield !initial.contains(ConnectivityResult.none);

  yield* connectivity.onConnectivityChanged.map(
    (results) => !results.contains(ConnectivityResult.none),
  );
});

/// Convenience sync accessor. Defaults to `true` (online) while the
/// stream's first value hasn't resolved yet, so we don't flash an
/// "offline" banner on app start.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).value ?? true;
});