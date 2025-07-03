import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_attestation/device_attestation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Attestation Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DeviceAttestationDemo(),
    );
  }
}

class DeviceAttestationDemo extends StatefulWidget {
  const DeviceAttestationDemo({super.key});

  @override
  State<DeviceAttestationDemo> createState() => _DeviceAttestationDemoState();
}

class _DeviceAttestationDemoState extends State<DeviceAttestationDemo> {
  final DeviceAttestationPlatform _attestationService =
      DeviceAttestationPlatform.instance;

  String _status = 'Not initialized';
  String _attestationResult = '';
  String? _currentKeyId;
  bool _isSupported = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    try {
      final supported = await _attestationService.isSupported();
      setState(() {
        _isSupported = supported;
        _status = supported
            ? 'Device supports attestation'
            : 'Device does not support attestation';
      });
    } catch (e) {
      setState(() {
        _status = 'Error checking support: $e';
      });
    }
  }

  Future<void> _initialize() async {
    if (!_isSupported) return;

    setState(() {
      _isLoading = true;
      _status = 'Initializing...';
    });

    try {
      // TODO: Replace with your actual Google Cloud project number
      const projectNumber = "581285986647";

      final success = await _attestationService.initialize(
        projectNumber: projectNumber,
      );
      setState(() {
        _status =
            success ? 'Initialized successfully' : 'Initialization failed';
      });
    } catch (e) {
      setState(() {
        _status = 'Initialization error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performAttestation() async {
    if (!_isSupported) return;

    setState(() {
      _isLoading = true;
      _status = 'Performing attestation...';
    });

    try {
      // Generate a unique challenge (in real app, this should come from your server)
      final challenge = 'challenge_${DateTime.now().millisecondsSinceEpoch}';

      print('Attestation challenge: $challenge');

      final result = await _attestationService.attest(challenge);

      print('Attestation result: $result');

      setState(() {
        _currentKeyId = result.keyId;
        _attestationResult = result.token;
        _status = 'Attestation successful! Type: ${result.type}';
      });

      // Copy token to clipboard for easy testing
      await Clipboard.setData(ClipboardData(text: result.token));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Attestation token copied to clipboard')),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Attestation failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAssertion() async {
    if (!_isSupported || _currentKeyId == null) return;

    setState(() {
      _isLoading = true;
      _status = 'Generating assertion...';
    });

    try {
      // Generate a unique challenge (in real app, this should come from your server)
      final challenge =
          'assertion_challenge_${DateTime.now().millisecondsSinceEpoch}';

      final result = await _attestationService.generateAssertion(
          challenge, _currentKeyId!);

      setState(() {
        _attestationResult = result.token;
        _status = 'Assertion generated successfully!';
      });

      // Copy token to clipboard for easy testing
      await Clipboard.setData(ClipboardData(text: result.token));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assertion token copied to clipboard')),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Assertion failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Attestation Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_currentKeyId != null) ...[
                      const SizedBox(height: 8),
                      Text('Key ID: $_currentKeyId'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _initialize,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Initialize'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed:
                  (_isLoading || !_isSupported) ? null : _performAttestation,
              child: const Text('Perform Attestation'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: (_isLoading || !_isSupported || _currentKeyId == null)
                  ? null
                  : _generateAssertion,
              child: const Text('Generate Assertion'),
            ),
            const SizedBox(height: 16),
            if (_attestationResult.isNotEmpty) ...[
              Text(
                'Attestation Result:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _attestationResult,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How it works:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Android: Uses Google Play Integrity API'),
                    const Text('• iOS: Uses Apple App Attest (iOS 14+)'),
                    const Text('• Tokens are copied to clipboard for testing'),
                    const Text('• Send tokens to your server for verification'),
                  ],
                ),
              ),
            ),
            const SizedBox(
                height: 24), // Extra bottom padding for better scrolling
          ],
        ),
      ),
    );
  }
}
