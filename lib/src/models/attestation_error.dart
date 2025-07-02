class AttestationError implements Exception {
  final String code;
  final String message;
  final dynamic details;

  AttestationError({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() {
    return 'AttestationError{code: $code, message: $message, details: $details}';
  }
}
