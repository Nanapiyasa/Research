import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // For ImageFilter
import 'firebase_options.dart';
import 'Registration.dart';
import 'pages/home_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Down Syndrome Level Detection System',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Poppins',
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _errorText = "";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Modern vibrant color palette (matching Registration page)
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _errorText = "";
        });

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
                      'Signing In',
                      style: TextStyle(
                        color: primaryPurple,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please wait...',
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

        final authResult = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final user = authResult.user;

        if (user != null) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

          Navigator.pop(context); // Close loading dialog

          if (userDoc.exists) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => HomeDashboard()
              ),
            );
          } else {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'email': user.email,
              'role': 'user',
              'createdAt': FieldValue.serverTimestamp(),
            });

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeDashboard(),
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        Navigator.pop(context); // Close loading dialog

        setState(() {
          _errorText = "Invalid Login Details.";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Invalid login details. Please check your email and password.')),
              ],
            ),
            backgroundColor: accentPink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.all(16),
          ),
        );
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        print("Error: $e");
      }
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
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
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

                                        // Main logo with puzzle pieces for Down Syndrome
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
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.favorite,
                                                    size: 40,
                                                    color: Colors.white,
                                                  ),
                                                  Positioned(
                                                    top: 12,
                                                    left: 25,
                                                    child: Icon(
                                                      Icons.psychology,
                                                      size: 24,
                                                      color: Colors.white.withOpacity(0.9),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 20),

                                  // Modern Title with gradient
                                  Text(
                                    'WELCOME BACK',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      foreground: Paint()
                                        ..shader = LinearGradient(
                                          colors: [primaryPurple, accentPink],
                                        ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                                    ),
                                  ),

                                  SizedBox(height: 8),

                                  Container(
                                    width: 60,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [primaryPurple, accentPink],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),

                                  SizedBox(height: 20),

                                  // Welcome Text
                                  Column(
                                    children: [
                                      Text(
                                        'Down Syndrome Detection System',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: primaryPurple,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Sign in to monitor and track progress',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 30),

                                  // Email Field with modern design
                                  _buildModernTextField(
                                    controller: _emailController,
                                    label: 'Email Address',
                                    icon: Icons.email_outlined,
                                    color: primaryPurple,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 16),

                                  // Password Field with modern design
                                  _buildModernTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    color: accentPink,
                                    isPassword: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 16),

                                  // Forgot Password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        // Handle forgot password
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: secondaryBlue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 10),

                                  // Error message if any
                                  if (_errorText.isNotEmpty)
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: accentPink.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: accentPink),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error, color: accentPink),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _errorText,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: accentPink,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  SizedBox(height: 20),

                                  // Buttons Row
                                  Row(
                                    children: [
                                      // Login Button
                                      Expanded(
                                        child: Container(
                                          height: 55,
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
                                            onPressed: _loginUser,
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
                                                  'Sign In',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(
                                                  Icons.arrow_forward,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(width: 12),

                                      // Register Button
                                      Expanded(
                                        child: Container(
                                          height: 55,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: primaryPurple,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: primaryPurple.withOpacity(0.2),
                                                blurRadius: 10,
                                                offset: Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => AddUserPage()),
                                              );
                                            },
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
                                                  'Register',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    foreground: Paint()
                                                      ..shader = LinearGradient(
                                                        colors: [primaryPurple, accentPink],
                                                      ).createShader(Rect.fromLTWH(0, 0, 100, 30)),
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(
                                                  Icons.person_add,
                                                  color: primaryPurple,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 30),

                                  // Modern Footer with decorative elements
                                  Column(
                                    children: [
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
                                              'Supporting Every Journey',
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
                                      SizedBox(height: 12),
                                      Text(
                                        '© 2026 Down Syndrome Detection System',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(3, (index) => Container(
                                          width: 6,
                                          height: 6,
                                          margin: EdgeInsets.symmetric(horizontal: 3),
                                          decoration: BoxDecoration(
                                            gradient: RadialGradient(
                                              colors: [
                                                [primaryPurple, accentPink, accentTeal][index],
                                                [primaryPurple, accentPink, accentTeal][index].withOpacity(0.3),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        )),
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
    String? Function(String?)? validator,
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
        validator: validator,
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
}

// Custom painter for decorative pattern (matching Registration page)
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