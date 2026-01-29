/// Phone Authentication Exceptions
class PhoneAuthException implements Exception {
  final String message;
  final String code;

  PhoneAuthException(this.message, {this.code = 'unknown'});

  @override
  String toString() => 'PhoneAuthException: $message';
}

class InvalidPhoneNumberException extends PhoneAuthException {
  InvalidPhoneNumberException()
      : super('Invalid phone number format', code: 'invalid-phone');
}

class TooManyRequestsException extends PhoneAuthException {
  TooManyRequestsException()
      : super('Too many SMS requests. Please try again later.',
            code: 'too-many-requests');
}

class InvalidVerificationCodeException extends PhoneAuthException {
  InvalidVerificationCodeException()
      : super('Invalid verification code', code: 'invalid-code');
}

class SessionExpiredException extends PhoneAuthException {
  SessionExpiredException()
      : super('Verification session expired. Please request a new code.',
            code: 'session-expired');
}

class NetworkException extends PhoneAuthException {
  NetworkException()
      : super('No internet connection', code: 'network-error');
}

class UnknownPhoneAuthException extends PhoneAuthException {
  UnknownPhoneAuthException(String message)
      : super(message, code: 'unknown');
}
