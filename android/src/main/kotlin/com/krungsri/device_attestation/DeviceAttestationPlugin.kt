package com.krungsri.device_attestation

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.google.android.play.core.integrity.IntegrityManager
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import com.google.android.play.core.integrity.IntegrityTokenResponse
import com.google.android.gms.tasks.Task
import android.util.Log
import android.os.Handler
import android.os.Looper
import java.util.concurrent.TimeUnit

class DeviceAttestationPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var integrityManager: IntegrityManager? = null
    private var cloudProjectNumber: Long? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "device_attestation")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        integrityManager = IntegrityManagerFactory.create(context)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val projectNumber = call.argument<String>("projectNumber")
                initialize(projectNumber, result)
            }
            "attest" -> {
                val challenge = call.argument<String>("challenge")
                if (challenge != null) {
                    attest(challenge, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Challenge is required", null)
                }
            }
            "generateAssertion" -> {
                val challenge = call.argument<String>("challenge")
                val keyId = call.argument<String>("keyId")
                if (challenge != null && keyId != null) {
                    generateAssertion(challenge, keyId, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Challenge and keyId are required", null)
                }
            }
            "isSupported" -> {
                isSupported(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun initialize(projectNumber: String?, result: MethodChannel.Result) {
        try {
            // Set the cloud project number from Dart
            if (projectNumber != null) {
                cloudProjectNumber = projectNumber.toLongOrNull()
                if (cloudProjectNumber == null) {
                    result.error("INVALID_PROJECT_NUMBER", "Invalid project number format: $projectNumber", null)
                    return
                }
                Log.d("DeviceAttestationPlugin", "Cloud project number set to: $cloudProjectNumber")
            } else {
                Log.w("DeviceAttestationPlugin", "No project number provided during initialization")
            }
            
            // Play Integrity doesn't require explicit initialization
            // Just verify that the service is available
            if (integrityManager != null) {
                result.success(true)
            } else {
                result.error("INITIALIZATION_FAILED", "Failed to initialize Play Integrity", null)
            }
        } catch (e: Exception) {
            result.error("INITIALIZATION_FAILED", e.message, null)
        }
    }

    private fun attest(challenge: String, result: MethodChannel.Result) {
        Log.d("DeviceAttestationPlugin", "Starting attestation with challenge: $challenge")
        
        // Check if cloud project number is configured
        if (cloudProjectNumber == null || cloudProjectNumber == 0L) {
            Log.e("DeviceAttestationPlugin", "Cloud project number is not configured. Please call initialize() with a valid project number first.")
            result.error("CONFIGURATION_ERROR", 
                "Cloud project number is not configured. Please call initialize() with your Google Cloud project number first.", 
                null)
            return
        }
        
        // Check if running on emulator
        if (isEmulator()) {
            Log.d("DeviceAttestationPlugin", "Detected emulator - providing mock response")
            val mockToken = "mock_integrity_token_${System.currentTimeMillis()}"
            val resultMap = hashMapOf<String, Any>(
                "token" to mockToken,
                "type" to "playIntegrity"
            )
            result.success(resultMap)
            return
        }
        
        integrityManager?.let { manager ->
            try {
                // Convert challenge to Base64-encoded bytes as required by Play Integrity
                val challengeBytes = challenge.toByteArray(Charsets.UTF_8)
                val challengeBase64 = android.util.Base64.encodeToString(challengeBytes, android.util.Base64.NO_WRAP)
                
                Log.d("DeviceAttestationPlugin", "Base64 challenge: $challengeBase64")
                
                val integrityTokenRequest = IntegrityTokenRequest.builder()
                    .setNonce(challengeBase64)
                    .setCloudProjectNumber(cloudProjectNumber ?: 0L)
                    .build()

                Log.d("DeviceAttestationPlugin", "Requesting integrity token...")
                
                val task = manager.requestIntegrityToken(integrityTokenRequest)
                
                // Add timeout handling
                val timeoutHandler = Handler(Looper.getMainLooper())
                var isCompleted = false
                
                val timeoutRunnable = Runnable {
                    if (!isCompleted) {
                        Log.e("DeviceAttestationPlugin", "Attestation request timed out")
                        result.error("ATTESTATION_TIMEOUT", "Request timed out after 30 seconds", null)
                    }
                }
                
                timeoutHandler.postDelayed(timeoutRunnable, 30000) // 30 second timeout
                
                task.addOnSuccessListener { response: IntegrityTokenResponse ->
                        isCompleted = true
                        timeoutHandler.removeCallbacks(timeoutRunnable)
                        Log.d("DeviceAttestationPlugin", "Attestation successful")
                        val token = response.token()
                        val resultMap = hashMapOf<String, Any>(
                            "token" to token,
                            "type" to "playIntegrity"
                        )
                        result.success(resultMap)
                    }
                    .addOnFailureListener { exception ->
                        isCompleted = true
                        timeoutHandler.removeCallbacks(timeoutRunnable)
                        Log.e("DeviceAttestationPlugin", "Attestation failed: ${exception.message}", exception)
                        result.error("ATTESTATION_FAILED", exception.message ?: "Unknown error", null)
                    }
            } catch (e: Exception) {
                Log.e("DeviceAttestationPlugin", "Exception during attestation: ${e.message}", e)
                result.error("ATTESTATION_FAILED", e.message, null)
            }
        } ?: run {
            Log.e("DeviceAttestationPlugin", "Integrity manager is null")
            result.error("NOT_INITIALIZED", "Integrity manager not available", null)
        }
    }

    private fun generateAssertion(challenge: String, keyId: String, result: MethodChannel.Result) {
        // For Play Integrity, assertions are similar to attestations
        // The keyId parameter is not used in Play Integrity but kept for API consistency
        attest(challenge, result)
    }

    private fun isSupported(result: MethodChannel.Result) {
        try {
            // Check if Play Integrity is supported on this device
            val isSupported = integrityManager != null
            result.success(isSupported)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun isEmulator(): Boolean {
        return (android.os.Build.FINGERPRINT.startsWith("generic") ||
                android.os.Build.FINGERPRINT.startsWith("unknown") ||
                android.os.Build.MODEL.contains("google_sdk") ||
                android.os.Build.MODEL.contains("Emulator") ||
                android.os.Build.MODEL.contains("Android SDK built for x86") ||
                android.os.Build.MANUFACTURER.contains("Genymotion") ||
                (android.os.Build.BRAND.startsWith("generic") && android.os.Build.DEVICE.startsWith("generic")) ||
                "google_sdk" == android.os.Build.PRODUCT)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}