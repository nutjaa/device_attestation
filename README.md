# Device Attestation Flutter Plugin

This Flutter plugin provides device attestation features for both Android and iOS platforms. It allows developers to verify the integrity of the device and ensure that the application is running in a secure environment.

## Features

- Device attestation for Android and iOS
- Easy integration with Flutter applications
- Supports method channels for communication between Dart and native code

## Installation

To use the `device_attestation` plugin, add it to your `pubspec.yaml` file:

```yaml
dependencies:
  device_attestation:
    git:
      url: https://github.com/yourusername/device_attestation.git
```

## Android Configuration

For Android, you need to configure the Google Play Integrity API:

1. **Enable Play Integrity API** in your Google Cloud Console
2. **Get your Cloud Project Number** from the Google Cloud Console Project Info page
3. **Pass the project number** when initializing the plugin in your Dart code:

```dart
await DeviceAttestationPlatform.instance.initialize(
  projectNumber: "YOUR_ACTUAL_PROJECT_NUMBER",
);
```

**Important**: Replace `YOUR_ACTUAL_PROJECT_NUMBER` with your actual Google Cloud project number (not project ID).

### Finding Your Project Number:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to "Project Info" in the dashboard
4. Copy the "Project number" (not "Project ID")

## iOS Configuration

For iOS, the plugin uses Apple's App Attest API (iOS 14+). No additional configuration is required.

## Usage

Import the plugin in your Dart code:

```dart
import 'package:device_attestation/device_attestation.dart';
```

### Example

Here is a simple example of how to use the device attestation plugin:

```dart
import 'package:device_attestation/device_attestation.dart';

void main() async {
  // Initialize the attestation service
  await DeviceAttestationPlatform.instance.initialize(
    projectNumber: "123456789012", // Your Google Cloud project number for Android
  );

  // Check if attestation is supported
  final isSupported = await DeviceAttestationPlatform.instance.isSupported();

  if (isSupported) {
    // Perform attestation
    final result = await DeviceAttestationPlatform.instance.attest("your-challenge-string");
    print('Attestation token: ${result.token}');
    print('Attestation type: ${result.type}');
  }
}
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
