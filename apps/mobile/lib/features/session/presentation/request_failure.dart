import '../../../common/network_failure.dart';
import '../domain/session_exceptions.dart';

/// How a request ended when the session expired or the network failed; `expired` false and
/// `error` null when it did not fail that way.
typedef RequestFailure = ({bool expired, Object? error});

/// Runs [action] and returns the session expiry or the network failure it ended with.
Future<RequestFailure> captureRequestFailure(
  Future<void> Function() action,
) async {
  try {
    await action();
  } on SessionExpired {
    return (expired: true, error: null);
  } on FalloDeRed catch (e) {
    return (expired: false, error: e);
  }
  return (expired: false, error: null);
}
