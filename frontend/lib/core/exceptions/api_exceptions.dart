class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'Oturum süresi doldu. Lütfen tekrar giriş yapın.']);
}

class NotFoundException extends ApiException {
  NotFoundException([super.message = 'Kayıt bulunamadı.']);
}

class ValidationException extends ApiException {
  ValidationException(super.message, {this.details});

  final dynamic details;
}
