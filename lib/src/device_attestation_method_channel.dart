import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'device_attestation_platform_interface.dart';
import 'models/attestation_result.dart';
import 'models/attestation_error.dart';

class MethodChannelDeviceAttestation extends DeviceAttestationPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('device_attestation');

  @override
  Future<bool> initialize({String? projectNumber, String? keyId}) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('initialize', {
        if (projectNumber != null) 'projectNumber': projectNumber,
        if (keyId != null) 'keyId': keyId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw AttestationError(
        code: e.code,
        message: e.message ?? 'Failed to initialize attestation service',
        details: e.details,
      );
    }
  }

  @override
  Future<AttestationResult> attest(String challenge, {String? keyId}) async {
    try {
      final result =
          await methodChannel.invokeMethod<Map<Object?, Object?>>('attest', {
        'challenge': challenge,
        if (keyId != null) 'keyId': keyId,
      });

      if (result == null) {
        throw AttestationError(
          code: 'ATTESTATION_FAILED',
          message: 'Received null result from platform',
        );
      }

      return AttestationResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw AttestationError(
        code: e.code,
        message: e.message ?? 'Attestation failed',
        details: e.details,
      );
    }
  }

  @override
  Future<AttestationResult> generateAssertion(String challenge, String keyId,
      {Map<String, dynamic>? clientData}) async {
    try {
      final result = await methodChannel
          .invokeMethod<Map<Object?, Object?>>('generateAssertion', {
        'challenge': challenge,
        'keyId': keyId,
        if (clientData != null) 'clientData': clientData,
      });

      if (result == null) {
        throw AttestationError(
          code: 'ASSERTION_FAILED',
          message: 'Received null result from platform',
        );
      }

      return AttestationResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw AttestationError(
        code: e.code,
        message: e.message ?? 'Assertion generation failed',
        details: e.details,
      );
    }
  }

  @override
  Future<bool> isSupported() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } on PlatformException catch (e) {
      throw AttestationError(
        code: e.code,
        message: e.message ?? 'Failed to check attestation support',
        details: e.details,
      );
    }
  }
}
