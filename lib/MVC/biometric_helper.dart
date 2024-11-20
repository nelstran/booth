import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthHelper {
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  
  // Check iOS biometric privacy status
  Future<bool> checkBiometricPrivacyStatus() async {
    if (Platform.isIOS) {
      try {
        final authStatus = await auth.getAvailableBiometrics();
        
        // Check if user has denied biometric permission
        if (authStatus.isEmpty) {
          // Guide user to settings
          return false;
        }
        return true;
      } catch (e) {
        debugPrint('Error checking biometric privacy status: $e');
        return false;
      }
    }
    return true;  // Non-iOS platforms
  }

  // Check if biometrics is available and enabled
  Future<bool> isBiometricsAvailable() async {
    try {
      // First check privacy status on iOS
      if (Platform.isIOS && !await checkBiometricPrivacyStatus()) {
        return false;
      }

      // Then check if the device supports biometrics
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      
      if (!canAuthenticate) return false;
      
      // Get available biometrics (needed for iOS)
      final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      
      // iOS specific check
      if (Platform.isIOS) {
        return availableBiometrics.contains(BiometricType.face) || 
               availableBiometrics.contains(BiometricType.fingerprint);
      }
      
      return canAuthenticate;
    } catch (e) {
      debugPrint('Error checking biometrics availability: $e');
      return false;
    }
  }

  String getAuthMessage() {
    if (Platform.isIOS) {
      return 'Authenticate using Face ID or Touch ID';
    }
    return 'Please authenticate to login';
  }
  
  // Perform biometric authentication
  Future<BiometricAuthResult> authenticateWithBiometrics() async {
    try {
      // Check privacy status first on iOS
      if (Platform.isIOS && !await checkBiometricPrivacyStatus()) {
        return BiometricAuthResult(
          success: false,
          error: 'Biometric authentication permission not granted'
        );
      }

      if (!await isBiometricsAvailable()) {
        return BiometricAuthResult(
          success: false,
          error: 'Biometric authentication not available'
        );
      }

      const authOptions = AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
        useErrorDialogs: true,
        sensitiveTransaction: true,
      );

      final bool authenticated = await auth.authenticate(
        localizedReason: getAuthMessage(),
        options: authOptions,
      );

      if (authenticated) {
        final storedEmail = await storage.read(key: 'biometric_user_email');
        final storedPassword = await storage.read(key: 'biometric_user_password');

        if (storedEmail != null && storedPassword != null) {
          return BiometricAuthResult(
            success: true,
            credentials: BiometricCredentials(
              email: storedEmail,
              password: storedPassword,
            ),
          );
        }
      }
      return BiometricAuthResult(
        success: false,
        error: 'Authentication failed'
      );
      
    } on PlatformException catch (e) {
      // Handle iOS-specific exceptions
      String errorMessage;
      
      switch (e.code) {
        case 'NotAvailable':
          errorMessage = 'Biometric authentication not set up on device';
          break;
        case 'NotEnrolled':
          errorMessage = 'No biometric authentication methods enrolled';
          break;
        case 'LockedOut':
          errorMessage = 'Biometric authentication is temporarily locked';
          break;
        case 'PermanentlyLockedOut':
          errorMessage = 'Biometric authentication is permanently locked';
          break;
        case 'passcode_not_set':
          errorMessage = 'Please set up device passcode to use biometric authentication';
          break;
        case 'SecurityError':
          errorMessage = Platform.isIOS 
            ? 'Biometric permission denied. Please enable in Settings'
            : 'Security error occurred';
          break;
        default:
          errorMessage = 'Authentication error: ${e.message}';
      }
      
      return BiometricAuthResult(
        success: false,
        error: errorMessage
      );
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        error: 'Unexpected error occurred: $e'
      );
    }
  }

  // Save credentials securely
  Future<bool> saveCredentials(String email, String password) async {
    try {
      // Check privacy status first on iOS
      if (Platform.isIOS && !await checkBiometricPrivacyStatus()) {
        return false;
      }

      await storage.write(key: 'biometric_user_email', value: email);
      await storage.write(key: 'biometric_user_password', value: password);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isBiometricEnabled', true);
      
      return true;
    } catch (e) {
      debugPrint('Error saving credentials: $e');
      return false;
    }
  }

  // Clear stored credentials
  Future<void> clearCredentials() async {
    try {
      await storage.delete(key: 'biometric_user_email');
      await storage.delete(key: 'biometric_user_password');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isBiometricEnabled', false);
    } catch (e) {
      debugPrint('Error clearing credentials: $e');
    }
  }
}

// Result class for better error handling
class BiometricAuthResult {
  final bool success;
  final String? error;
  final BiometricCredentials? credentials;

  BiometricAuthResult({
    required this.success,
    this.error,
    this.credentials,
  });
}

class BiometricCredentials {
  final String email;
  final String password;

  BiometricCredentials({
    required this.email,
    required this.password,
  });
}