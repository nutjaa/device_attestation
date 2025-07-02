import Flutter
import UIKit
import DeviceCheck
import CryptoKit
import CommonCrypto

@available(iOS 14.0, *)
public class DeviceAttestationPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "device_attestation", binaryMessenger: registrar.messenger())
        let instance = DeviceAttestationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(call: call, result: result)
        case "attest":
            attest(call: call, result: result)
        case "generateAssertion":
            generateAssertion(call: call, result: result)
        case "isSupported":
            isSupported(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 14.0, *) else {
            result(FlutterError(code: "UNSUPPORTED_VERSION", message: "App Attest requires iOS 14.0 or later", details: nil))
            return
        }
        
        guard DCAppAttestService.shared.isSupported else {
            result(FlutterError(code: "UNSUPPORTED_DEVICE", message: "App Attest is not supported on this device", details: nil))
            return
        }
        
        result(true)
    }
    
    private func attest(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 14.0, *) else {
            result(FlutterError(code: "UNSUPPORTED_VERSION", message: "App Attest requires iOS 14.0 or later", details: nil))
            return
        }
        
        guard let args = call.arguments as? [String: Any],
              let challenge = args["challenge"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Challenge is required", details: nil))
            return
        }
        
        let keyId = args["keyId"] as? String
        
        if let existingKeyId = keyId {
            // Use existing key for assertion
            generateAssertionWithKeyId(existingKeyId, challenge: challenge, result: result)
        } else {
            // Generate new key and attest
            generateNewAttestation(challenge: challenge, result: result)
        }
    }
    
    private func generateAssertion(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 14.0, *) else {
            result(FlutterError(code: "UNSUPPORTED_VERSION", message: "App Attest requires iOS 14.0 or later", details: nil))
            return
        }
        
        guard let args = call.arguments as? [String: Any],
              let challenge = args["challenge"] as? String,
              let keyId = args["keyId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Challenge and keyId are required", details: nil))
            return
        }
        
        generateAssertionWithKeyId(keyId, challenge: challenge, result: result)
    }
    
    private func isSupported(result: @escaping FlutterResult) {
        if #available(iOS 14.0, *) {
            result(DCAppAttestService.shared.isSupported)
        } else {
            result(false)
        }
    }
    
    private func generateNewAttestation(challenge: String, result: @escaping FlutterResult) {
        guard #available(iOS 14.0, *) else {
            result(FlutterError(code: "UNSUPPORTED_VERSION", message: "App Attest requires iOS 14.0 or later", details: nil))
            return
        }
        
        // Generate a new key
        DCAppAttestService.shared.generateKey { [weak self] keyId, error in
            if let error = error {
                result(FlutterError(code: "KEY_GENERATION_FAILED", message: error.localizedDescription, details: nil))
                return
            }
            
            guard let keyId = keyId else {
                result(FlutterError(code: "KEY_GENERATION_FAILED", message: "Failed to generate key", details: nil))
                return
            }
            
            // Create client data hash
            guard let clientDataHash = self?.createClientDataHash(challenge: challenge) else {
                result(FlutterError(code: "HASH_CREATION_FAILED", message: "Failed to create client data hash", details: nil))
                return
            }
            
            // Attest the key
            DCAppAttestService.shared.attestKey(keyId, clientDataHash: clientDataHash) { attestationObject, error in
                if let error = error {
                    result(FlutterError(code: "ATTESTATION_FAILED", message: error.localizedDescription, details: nil))
                    return
                }
                
                guard let attestationObject = attestationObject else {
                    result(FlutterError(code: "ATTESTATION_FAILED", message: "Attestation object is nil", details: nil))
                    return
                }
                
                let token = attestationObject.base64EncodedString()
                let resultMap: [String: Any] = [
                    "token": token,
                    "keyId": keyId,
                    "type": "appAttest"
                ]
                result(resultMap)
            }
        }
    }
    
    private func generateAssertionWithKeyId(_ keyId: String, challenge: String, result: @escaping FlutterResult) {
        guard #available(iOS 14.0, *) else {
            result(FlutterError(code: "UNSUPPORTED_VERSION", message: "App Attest requires iOS 14.0 or later", details: nil))
            return
        }
        
        // Create client data hash
        guard let clientDataHash = createClientDataHash(challenge: challenge) else {
            result(FlutterError(code: "HASH_CREATION_FAILED", message: "Failed to create client data hash", details: nil))
            return
        }
        
        // Generate assertion
        DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientDataHash) { assertion, error in
            if let error = error {
                result(FlutterError(code: "ASSERTION_FAILED", message: error.localizedDescription, details: nil))
                return
            }
            
            guard let assertion = assertion else {
                result(FlutterError(code: "ASSERTION_FAILED", message: "Assertion is nil", details: nil))
                return
            }
            
            let token = assertion.base64EncodedString()
            let resultMap: [String: Any] = [
                "token": token,
                "keyId": keyId,
                "type": "assertion"
            ]
            result(resultMap)
        }
    }
    
    private func createClientDataHash(challenge: String) -> Data? {
        // Create client data JSON
        let clientData: [String: Any] = [
            "challenge": challenge,
            "origin": Bundle.main.bundleIdentifier ?? "",
            "type": "webauthn.get"
        ]
        
        guard let clientDataJSON = try? JSONSerialization.data(withJSONObject: clientData, options: []) else {
            return nil
        }
        
        // Hash the client data
        return Data(SHA256.hash(data: clientDataJSON))
    }
}

// Fallback implementation for iOS versions < 14.0
public class DeviceAttestationPluginLegacy: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "device_attestation", binaryMessenger: registrar.messenger())
        let instance = DeviceAttestationPluginLegacy()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize", "attest", "generateAssertion":
            result(FlutterError(code: "UNSUPPORTED_VERSION", message: "App Attest requires iOS 14.0 or later", details: nil))
        case "isSupported":
            result(false)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}