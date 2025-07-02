class AttestationResult {
  final String token;
  final String? keyId;
  final Map<String, dynamic>? metadata;
  final AttestationType type;

  AttestationResult({
    required this.token,
    this.keyId,
    this.metadata,
    required this.type,
  });

  factory AttestationResult.fromMap(Map<String, dynamic> map) {
    return AttestationResult(
      token: map['token'] as String,
      keyId: map['keyId'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
      type: AttestationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => AttestationType.unknown,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'token': token,
      if (keyId != null) 'keyId': keyId,
      if (metadata != null) 'metadata': metadata,
      'type': type.toString().split('.').last,
    };
  }

  @override
  String toString() {
    return 'AttestationResult{token: ${token.substring(0, 20)}..., keyId: $keyId, type: $type}';
  }
}

enum AttestationType {
  playIntegrity,
  appAttest,
  assertion,
  unknown,
}
