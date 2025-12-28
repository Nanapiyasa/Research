import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Login state
  bool _isLoggedIn = false;
  String? _currentUserName;
  String? _currentQRCode;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUserName => _currentUserName;
  String? get currentQRCode => _currentQRCode;

  /// Scan QR code and authenticate user
  Future<Map<String, dynamic>> scanAndLogin() async {
    try {
      final String qrCode = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancel',
        true,
        ScanMode.QR,
      );

      if (qrCode != '-1') {
        _currentQRCode = qrCode;
        _isLoggedIn = true;
        _currentUserName = 'Player One';

        return {
          'success': true,
          'message': 'Logged in successfully!',
          'qrCode': qrCode,
        };
      } else {
        return {
          'success': false,
          'message': 'QR code scan cancelled',
        };
      }
    } on PlatformException catch (e) {
      return {
        'success': false,
        'message': 'Error scanning QR code: ${e.message}',
      };
    }
  }

  /// Logout user
  void logout() {
    _isLoggedIn = false;
    _currentUserName = null;
    _currentQRCode = null;
  }

  /// Reset auth service (optional)
  void reset() {
    logout();
  }
}
