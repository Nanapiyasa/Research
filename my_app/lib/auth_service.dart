import 'package:flutter/services.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart'; // Commented out as it may cause issues

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
  String? _currentStudentId;
  String? _currentQRCode;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUserName => _currentUserName;
  String? get currentStudentId => _currentStudentId;
  String? get currentQRCode => _currentQRCode;

  /// Scan QR code and authenticate user
  Future<Map<String, dynamic>> scanAndLogin() async {
    try {
      // Mock QR code scanning for now since flutter_barcode_scanner may have issues
      // final String qrCode = await FlutterBarcodeScanner.scanBarcode(
      //   '#ff6666',
      //   'Cancel',
      //   true,
      //   ScanMode.QR,
      // );
      
      // Simulating QR code scan with mock data
      await Future.delayed(Duration(seconds: 1)); // Simulate scan delay
      final String qrCode = "MOCK_QR_CODE_${DateTime.now().millisecondsSinceEpoch}";

      if (qrCode != '-1') {
        _currentQRCode = qrCode;
        _isLoggedIn = true;
        _currentUserName = 'Player One';
        _currentStudentId = null;

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
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  /// Login with username and password
  Map<String, dynamic> login(String username, {String? studentId}) {
    _isLoggedIn = true;
    _currentUserName = username;
    _currentStudentId = studentId;
    _currentQRCode = "LOGIN_${DateTime.now().millisecondsSinceEpoch}";
    return {
      'success': true,
      'message': 'Logged in successfully!',
      'username': username,
      'studentId': studentId,
    };
  }

  /// Logout user
  void logout() {
    _isLoggedIn = false;
    _currentUserName = null;
    _currentStudentId = null;
    _currentQRCode = null;
  }

  /// Reset auth service (optional)
  void reset() {
    logout();
  }
}
