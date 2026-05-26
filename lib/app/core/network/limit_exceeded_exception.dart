import 'api_exception.dart';

/// Thrown after navigating to subscription for [ApiFlags.limitExceeded].
class LimitExceededException extends ApiException {
  LimitExceededException(super.message);
}
