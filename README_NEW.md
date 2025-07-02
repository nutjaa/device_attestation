# Device Attestation Plugin

A Flutter plugin that simplifies app attestation by using Apple's App Attest and Google's Play Integrity to generate tokens for your server to decrypt and verify reliable device access.

## Features

- ✅ **Android Play Integrity API** - Verify app authenticity and device integrity on Android
- ✅ **iOS App Attest** - Generate cryptographic proofs of app authenticity on iOS 14+
- ✅ **Unified API** - Same interface for both platforms
- ✅ **Challenge-based authentication** - Secure server-client attestation flow
- ✅ **Assertion generation** - Create subsequent proofs after initial attestation

## Platform Support

| Platform | Version | API |
|----------|---------|-----|
| Android  | API 21+ | Google Play Integrity |
| iOS      | 14.0+   | Apple App Attest |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  device_attestation: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Setup

### Android Setup

1. **Enable Play Integrity API** in your Google Cloud Console:
   - Go to Google Cloud Console
   - Select your project
   - Enable the Play Integrity API
   - Create credentials if needed

2. **Add to your `android/app/build.gradle`:**
   ```gradle
   android {
       compileSdkVersion 31
       defaultConfig {
           minSdkVersion 21
           targetSdkVersion 31
       }
   }
   ```

### iOS Setup

1. **Enable App Attest capability** in your Apple Developer account:
   - Go to Apple Developer Portal
   - Select your app identifier
   - Enable "App Attest" capability

2. **Add to your `ios/Runner/Info.plist`:**
   ```xml
   <key>NSAppAttestEnvironment</key>
   <string>development</string> <!-- or 'production' for release -->
   ```

3. **Minimum iOS version** in `ios/Podfile`:
   ```ruby
   platform :ios, '14.0'
   ```

## Usage

### Basic Implementation

```dart
import 'package:device_attestation/device_attestation.dart';

class AttestationService {
  final DeviceAttestationPlatform _attestation = DeviceAttestationPlatform.instance;

  Future<bool> initializeAttestation() async {
    try {
      // Check if device supports attestation
      final isSupported = await _attestation.isSupported();
      if (!isSupported) {
        print('Device does not support attestation');
        return false;
      }

      // Initialize the attestation service
      final initialized = await _attestation.initialize();
      return initialized;
    } catch (e) {
      print('Initialization failed: $e');
      return false;
    }
  }

  Future<String?> performAttestation(String challenge) async {
    try {
      final result = await _attestation.attest(challenge);
      print('Attestation successful: ${result.type}');
      
      // Store the keyId for future assertions (iOS only)
      if (result.keyId != null) {
        // Save keyId securely for later use
        await _saveKeyId(result.keyId!);
      }
      
      return result.token;
    } catch (e) {
      print('Attestation failed: $e');
      return null;
    }
  }

  Future<String?> generateAssertion(String challenge) async {
    try {
      // Retrieve stored keyId (iOS only)
      final keyId = await _getStoredKeyId();
      if (keyId == null) {
        throw Exception('No keyId found. Perform initial attestation first.');
      }

      final result = await _attestation.generateAssertion(challenge, keyId);
      return result.token;
    } catch (e) {
      print('Assertion failed: $e');
      return null;
    }
  }

  Future<void> _saveKeyId(String keyId) async {
    // Implement secure storage (e.g., using flutter_secure_storage)
    // await secureStorage.write(key: 'attestation_key_id', value: keyId);
  }

  Future<String?> _getStoredKeyId() async {
    // Implement secure storage retrieval
    // return await secureStorage.read(key: 'attestation_key_id');
    return null;
  }
}
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:device_attestation/device_attestation.dart';

class AttestationDemo extends StatefulWidget {
  @override
  _AttestationDemoState createState() => _AttestationDemoState();
}

class _AttestationDemoState extends State<AttestationDemo> {
  final DeviceAttestationPlatform _attestation = DeviceAttestationPlatform.instance;
  String _status = 'Not initialized';
  String? _currentKeyId;

  Future<void> _performAttestation() async {
    setState(() => _status = 'Performing attestation...');

    try {
      // In a real app, get this challenge from your server
      final challenge = 'unique_challenge_${DateTime.now().millisecondsSinceEpoch}';
      
      final result = await _attestation.attest(challenge);
      
      setState(() {
        _currentKeyId = result.keyId;
        _status = 'Attestation successful! Send token to server for verification.';
      });
      
      // Send result.token to your server for verification
      await _sendTokenToServer(result.token);
      
    } catch (e) {
      setState(() => _status = 'Attestation failed: $e');
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    // Implement your server communication
    print('Sending token to server: ${token.substring(0, 50)}...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Device Attestation')),
      body: Column(
        children: [
          Text(_status),
          ElevatedButton(
            onPressed: _performAttestation,
            child: Text('Perform Attestation'),
          ),
        ],
      ),
    );
  }
}
```

## API Reference

### Methods

#### `initialize({String? keyId}) -> Future<bool>`
Initialize the attestation service. Returns `true` if successful.

#### `attest(String challenge, {String? keyId}) -> Future<AttestationResult>`
Perform device attestation with the given challenge.

#### `generateAssertion(String challenge, String keyId, {Map<String, dynamic>? clientData}) -> Future<AttestationResult>`
Generate an assertion for subsequent authentications (iOS) or perform attestation (Android).

#### `isSupported() -> Future<bool>`
Check if the device supports attestation.

### Models

#### `AttestationResult`
```dart
class AttestationResult {
  final String token;          // Base64-encoded attestation token
  final String? keyId;         // Key identifier (iOS only)
  final AttestationType type;  // playIntegrity, appAttest, or assertion
  final Map<String, dynamic>? metadata;
}
```

#### `AttestationError`
```dart
class AttestationError implements Exception {
  final String code;
  final String message;
  final dynamic details;
}
```

## Error Handling

Common error codes and their meanings:

| Code | Platform | Description |
|------|----------|-------------|
| `UNSUPPORTED_VERSION` | iOS | iOS version < 14.0 |
| `UNSUPPORTED_DEVICE` | iOS | Device doesn't support App Attest |
| `KEY_GENERATION_FAILED` | iOS | Failed to generate attestation key |
| `ATTESTATION_FAILED` | Both | General attestation failure |
| `ASSERTION_FAILED` | iOS | Failed to generate assertion |
| `NOT_INITIALIZED` | Android | Play Integrity not available |
| `INVALID_ARGUMENT` | Both | Missing required parameters |

## Best Practices

1. **Server-side verification**: Always verify attestation tokens on your server, never trust client-side validation alone.

2. **Challenge generation**: Use cryptographically secure random challenges from your server.

3. **Key storage**: Securely store iOS keyIds using `flutter_secure_storage` or similar.

4. **Error handling**: Implement graceful fallbacks for devices that don't support attestation.

5. **Testing**: Use development/sandbox environments during development.

6. **Rate limiting**: Implement server-side rate limiting for attestation requests.

## Testing

Run the example app:

```bash
cd example
flutter run
```

The example demonstrates:
- Device support checking
- Attestation initialization
- Token generation
- Token copying to clipboard for server testing

## Troubleshooting

### Android Issues

- **Play Integrity not available**: Ensure Play Services are installed and up to date
- **API not enabled**: Enable Play Integrity API in Google Cloud Console
- **Wrong package name**: Verify package name matches your Google Cloud configuration

### iOS Issues

- **App Attest not available**: iOS 14+ required, check device compatibility
- **Capability not enabled**: Enable App Attest in Apple Developer Portal
- **Development vs Production**: Ensure correct environment in Info.plist

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Create an issue on GitHub
- Check existing issues for solutions
- Review Apple and Google documentation for platform-specific details
