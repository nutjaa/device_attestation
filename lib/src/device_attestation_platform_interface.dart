import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'device_attestation_method_channel.dart';
import 'models/attestation_result.dart';

abstract class DeviceAttestationPlatform extends PlatformInterface {
  DeviceAttestationPlatform() : super(token: _token);

  static final Object _token = Object();

  static DeviceAttestationPlatform _instance = MethodChannelDeviceAttestation();

  static DeviceAttestationPlatform get instance => _instance;

  static set instance(DeviceAttestationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialize the attestation service
  /// For iOS: This prepares App Attest service
  /// For Android: This initializes Play Integrity API with the provided project number
  /// [projectNumber] - Google Cloud project number (Android only, required for Play Integrity API)
  /// [keyId] - Optional key identifier (iOS only)
  Future<bool> initialize({String? projectNumber, String? keyId}) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Generate an attestation token
  /// [challenge] - A unique challenge string from your server
  /// [keyId] - Optional key identifier (iOS only)
  Future<AttestationResult> attest(String challenge, {String? keyId}) {
    throw UnimplementedError('attest() has not been implemented.');
  }

  /// Generate an assertion (for subsequent requests after initial attestation)
  /// [challenge] - A unique challenge string from your server
  /// [keyId] - Key identifier used during initial attestation
  /// [clientData] - Additional client data to include in the assertion
  Future<AttestationResult> generateAssertion(String challenge, String keyId,
      {Map<String, dynamic>? clientData}) {
    throw UnimplementedError('generateAssertion() has not been implemented.');
  }

  /// Check if the device supports attestation
  Future<bool> isSupported() {
    throw UnimplementedError('isSupported() has not been implemented.');
  }
}
