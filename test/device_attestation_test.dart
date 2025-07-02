import 'package:flutter_test/flutter_test.dart';
import 'package:device_attestation/device_attestation.dart'; 
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDeviceAttestationPlatform
    with MockPlatformInterfaceMixin
    implements DeviceAttestationPlatform {

  @override
  Future<bool> initialize({String? keyId}) async {
    return true;
  }

  @override
  Future<AttestationResult> attest(String challenge, {String? keyId}) async {
    if (challenge.isEmpty) {
      throw AttestationError(
        code: 'INVALID_CHALLENGE',
        message: 'Challenge cannot be empty',
      );
    }
    
    return AttestationResult(
      token: 'mock_attestation_token_${challenge.hashCode}',
      keyId: keyId ?? 'mock_key_id',
      type: AttestationType.appAttest,
      metadata: {'platform': 'test', 'challenge': challenge},
    );
  }

  @override
  Future<AttestationResult> generateAssertion(
    String challenge, 
    String keyId, 
    {Map<String, dynamic>? clientData}
  ) async {
    if (challenge.isEmpty || keyId.isEmpty) {
      throw AttestationError(
        code: 'INVALID_ARGUMENT',
        message: 'Challenge and keyId are required',
      );
    }
    
    return AttestationResult(
      token: 'mock_assertion_token_${challenge.hashCode}_${keyId.hashCode}',
      keyId: keyId,
      type: AttestationType.assertion,
      metadata: {
        'platform': 'test',
        'challenge': challenge,
        'clientData': clientData,
      },
    );
  }

  @override
  Future<bool> isSupported() async {
    return true;
  }
}

void main() {
  final DeviceAttestationPlatform initialPlatform = DeviceAttestationPlatform.instance;

  group('DeviceAttestationPlatform', () {
    setUp(() {
      DeviceAttestationPlatform.instance = MockDeviceAttestationPlatform();
    });

    tearDown(() {
      DeviceAttestationPlatform.instance = initialPlatform;
    });

    group('initialization', () {
      test('should initialize successfully', () async {
        final result = await DeviceAttestationPlatform.instance.initialize();
        expect(result, isTrue);
      });

      test('should initialize with keyId', () async {
        final result = await DeviceAttestationPlatform.instance.initialize(keyId: 'test_key');
        expect(result, isTrue);
      });
    });

    group('support check', () {
      test('should return true for supported devices', () async {
        final result = await DeviceAttestationPlatform.instance.isSupported();
        expect(result, isTrue);
      });
    });

    group('attestation', () {
      test('should perform attestation successfully', () async {
        const challenge = 'test_challenge_123';
        final result = await DeviceAttestationPlatform.instance.attest(challenge);
        
        expect(result, isA<AttestationResult>());
        expect(result.token, isNotEmpty);
        expect(result.token, contains('mock_attestation_token'));
        expect(result.keyId, equals('mock_key_id'));
        expect(result.type, equals(AttestationType.appAttest));
        expect(result.metadata?['challenge'], equals(challenge));
      });

      test('should perform attestation with custom keyId', () async {
        const challenge = 'test_challenge_456';
        const keyId = 'custom_key_id';
        final result = await DeviceAttestationPlatform.instance.attest(challenge, keyId: keyId);
        
        expect(result, isA<AttestationResult>());
        expect(result.keyId, equals(keyId));
      });

      test('should throw error for empty challenge', () async {
        expect(
          () => DeviceAttestationPlatform.instance.attest(''),
          throwsA(isA<AttestationError>()),
        );
      });
    });

    group('assertion generation', () {
      test('should generate assertion successfully', () async {
        const challenge = 'assertion_challenge_123';
        const keyId = 'test_key_id';
        final result = await DeviceAttestationPlatform.instance.generateAssertion(challenge, keyId);
        
        expect(result, isA<AttestationResult>());
        expect(result.token, isNotEmpty);
        expect(result.token, contains('mock_assertion_token'));
        expect(result.keyId, equals(keyId));
        expect(result.type, equals(AttestationType.assertion));
        expect(result.metadata?['challenge'], equals(challenge));
      });

      test('should generate assertion with client data', () async {
        const challenge = 'assertion_challenge_456';
        const keyId = 'test_key_id';
        final clientData = {'userId': '12345', 'timestamp': '2023-01-01'};
        
        final result = await DeviceAttestationPlatform.instance.generateAssertion(
          challenge, 
          keyId, 
          clientData: clientData,
        );
        
        expect(result.metadata?['clientData'], equals(clientData));
      });

      test('should throw error for empty challenge in assertion', () async {
        expect(
          () => DeviceAttestationPlatform.instance.generateAssertion('', 'key_id'),
          throwsA(isA<AttestationError>()),
        );
      });

      test('should throw error for empty keyId in assertion', () async {
        expect(
          () => DeviceAttestationPlatform.instance.generateAssertion('challenge', ''),
          throwsA(isA<AttestationError>()),
        );
      });
    });
  });

  group('AttestationResult', () {
    test('should create from map correctly', () {
      final map = {
        'token': 'test_token',
        'keyId': 'test_key_id',
        'type': 'appAttest',
        'metadata': {'platform': 'test'},
      };
      
      final result = AttestationResult.fromMap(map);
      
      expect(result.token, equals('test_token'));
      expect(result.keyId, equals('test_key_id'));
      expect(result.type, equals(AttestationType.appAttest));
      expect(result.metadata?['platform'], equals('test'));
    });

    test('should convert to map correctly', () {
      final result = AttestationResult(
        token: 'test_token',
        keyId: 'test_key_id',
        type: AttestationType.playIntegrity,
        metadata: {'platform': 'android'},
      );
      
      final map = result.toMap();
      
      expect(map['token'], equals('test_token'));
      expect(map['keyId'], equals('test_key_id'));
      expect(map['type'], equals('playIntegrity'));
      expect(map['metadata'], equals({'platform': 'android'}));
    });

    test('should handle unknown attestation type', () {
      final map = {
        'token': 'test_token',
        'type': 'unknown_type',
      };
      
      final result = AttestationResult.fromMap(map);
      expect(result.type, equals(AttestationType.unknown));
    });
  });

  group('AttestationError', () {
    test('should create error with all properties', () {
      final error = AttestationError(
        code: 'TEST_ERROR',
        message: 'Test error message',
        details: {'key': 'value'},
      );
      
      expect(error.code, equals('TEST_ERROR'));
      expect(error.message, equals('Test error message'));
      expect(error.details, equals({'key': 'value'}));
    });

    test('should create error without details', () {
      final error = AttestationError(
        code: 'SIMPLE_ERROR',
        message: 'Simple error',
      );
      
      expect(error.code, equals('SIMPLE_ERROR'));
      expect(error.message, equals('Simple error'));
      expect(error.details, isNull);
    });

    test('should have meaningful string representation', () {
      final error = AttestationError(
        code: 'TEST_ERROR',
        message: 'Test message',
        details: 'Test details',
      );
      
      final errorString = error.toString();
      expect(errorString, contains('TEST_ERROR'));
      expect(errorString, contains('Test message'));
      expect(errorString, contains('Test details'));
    });
  });
}