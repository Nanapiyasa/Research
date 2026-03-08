import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'dart:ui'; // Add this import for ImageFilter
import 'main.dart'; // Import the LoginPage

class AddUserPage extends StatefulWidget {
  @override
  _AddUserPageState createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> with TickerProviderStateMixin {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _contactNumberController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  String? _selectedGender;
  String _errorText = "";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Modern vibrant color palette
  final Color primaryPurple = Color(0xFF6B4EFF); // Electric Purple
  final Color secondaryBlue = Color(0xFF4A90E2); // Ocean Blue
  final Color accentPink = Color(0xFFFF6B9D); // Vibrant Pink
  final Color accentTeal = Color(0xFF20C997); // Mint Teal
  final Color accentOrange = Color(0xFFFFA36B); // Soft Orange
  final Color deepPurple = Color(0xFF3832A0); // Deep Indigo
  final Color lightPurple = Color(0xFF9D8CFF); // Light Purple
  final Color gradientStart = Color(0xFF667EEA); // Royal Blue
  final Color gradientEnd = Color(0xFF764BA2); // Royal Purple
  final Color bgLight = Color(0xFFF8F9FF); // Off White with purple tint
  final Color cardBg = Colors.white;
  final Color textPrimary = Color(0xFF2D3748); // Dark Gray
  final Color textSecondary = Color(0xFF718096); // Medium Gray
  final Color successGreen = Color(0xFF48BB78); // Success Green

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? accentPink : successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _addUser() async {
    // Validate inputs
    if (_nameController.text.isEmpty) {
      setState(() => _errorText = 'Name is required');
      _showSnackbar('Name is required', isError: true);
      return;
    }

    if (_contactNumberController.text.isEmpty) {
      setState(() => _errorText = 'Contact number is required');
      _showSnackbar('Contact number is required', isError: true);
      return;
    }

    if (_usernameController.text.isEmpty) {
      setState(() => _errorText = 'Email is required');
      _showSnackbar('Email is required', isError: true);
      return;
    }

    if (!_usernameController.text.contains('@')) {
      setState(() => _errorText = 'Enter a valid email address');
      _showSnackbar('Enter a valid email address', isError: true);
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _errorText = 'Password is required');
      _showSnackbar('Password is required', isError: true);
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorText = 'Password must be at least 6 characters');
      _showSnackbar('Password must be at least 6 characters', isError: true);
      return;
    }

    if (_selectedGender == null) {
      setState(() => _errorText = 'Please select gender');
      _showSnackbar('Please select gender', isError: true);
      return;
    }

    try {
      setState(() => _errorText = "");

      // Check if email exists
      QuerySnapshot usernameExists = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: _usernameController.text)
          .get();

      if (usernameExists.docs.isNotEmpty) {
        setState(() => _errorText = 'Email is already registered');
        _showSnackbar('Email is already registered', isError: true);
        return;
      }

      // Show modern loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cardBg, bgLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.2),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [primaryPurple, deepPurple],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Creating Account',
                    style: TextStyle(
                      color: primaryPurple,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please wait a moment...',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Create user
      UserCredential authUser = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      // Save user data
      Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'username': _usernameController.text.trim(),
        'gender': _selectedGender,
        'role': 'user',
        'created_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('users').doc(authUser.user!.uid).set(userData);

      Navigator.pop(context); // Close loading dialog

      _showSnackbar('Registration successful!', isError: false);

      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      });

    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close loading dialog

      String errorMessage = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email already in use';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password too weak';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email';
      }

      setState(() => _errorText = errorMessage);
      _showSnackbar(errorMessage, isError: true);

    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      setState(() => _errorText = 'Unexpected error occurred');
      _showSnackbar('Registration failed. Please try again.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryPurple,
              secondaryBlue,
              accentPink.withOpacity(0.8),
              accentTeal.withOpacity(0.6),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: cardBg.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 40,
                          offset: Offset(0, 20),
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: cardBg.withOpacity(0.9),
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Column(
                              children: [
                                // Modern Animated Header
                                Container(
                                  height: 120,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Animated circles background
                                      ...List.generate(3, (index) {
                                        return Positioned(
                                          left: 20 + (index * 30),
                                          top: 10,
                                          child: Container(
                                            width: 60 - (index * 15),
                                            height: 60 - (index * 15),
                                            decoration: BoxDecoration(
                                              gradient: RadialGradient(
                                                colors: [
                                                  [primaryPurple, secondaryBlue, accentPink][index].withOpacity(0.3),
                                                  Colors.transparent,
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        );
                                      }),

                                      // Main logo
                                      Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [primaryPurple, accentPink],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryPurple.withOpacity(0.5),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                            BoxShadow(
                                              color: accentPink.withOpacity(0.3),
                                              blurRadius: 30,
                                              spreadRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: CustomPaint(
                                          painter: _CirclePatternPainter(),
                                          child: Center(
                                            child: Icon(
                                              Icons.rocket_launch,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 20),

                                // Modern Title
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    foreground: Paint()
                                      ..shader = LinearGradient(
                                        colors: [primaryPurple, accentPink],
                                      ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                                  ),
                                ),

                                Text(
                                  'Create your account',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 16,
                                  ),
                                ),

                                SizedBox(height: 30),

                                // Input Fields with modern design
                                _buildModernTextField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  icon: Icons.person_outline,
                                  color: primaryPurple,
                                ),

                                SizedBox(height: 16),

                                _buildModernTextField(
                                  controller: _contactNumberController,
                                  label: 'Phone Number',
                                  icon: Icons.phone_outlined,
                                  color: secondaryBlue,
                                  keyboardType: TextInputType.phone,
                                ),

                                SizedBox(height: 16),

                                _buildModernTextField(
                                  controller: _usernameController,
                                  label: 'Email Address',
                                  icon: Icons.email_outlined,
                                  color: accentPink,
                                  keyboardType: TextInputType.emailAddress,
                                ),

                                SizedBox(height: 16),

                                _buildModernTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  color: accentTeal,
                                  isPassword: true,
                                ),

                                SizedBox(height: 16),

                                // Modern Gender Selection
                                Container(
                                  decoration: BoxDecoration(
                                    color: bgLight,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: primaryPurple.withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [primaryPurple, accentPink],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.people,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Text(
                                          'Gender',
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: _buildModernGenderChip('Male', primaryPurple),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: _buildModernGenderChip('Female', accentPink),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: 16),

                                // Error Message
                                if (_errorText.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: accentPink.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: accentPink),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error, color: accentPink),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _errorText,
                                            style: TextStyle(
                                              color: accentPink,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                SizedBox(height: 25),

                                // Modern Register Button
                                Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryPurple, accentPink, accentTeal],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryPurple.withOpacity(0.4),
                                        blurRadius: 15,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _addUser,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(
                                          Icons.arrow_forward,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: 20),

                                // Modern Login Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account?',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (context) => LoginPage()),
                                        );
                                      },
                                      child: Text(
                                        'Sign In',
                                        style: TextStyle(
                                          color: primaryPurple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 20),

                                // Modern Footer
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [primaryPurple, accentPink],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        'Secure • Fast • Reliable',
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 30,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [accentPink, primaryPurple],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: color, width: 2),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildModernGenderChip(String gender, Color color) {
    bool isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.transparent : color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            gender,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for decorative pattern
class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        center,
        radius - (i * 8),
        paint..color = Colors.white.withOpacity(0.1 + (i * 0.1)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}