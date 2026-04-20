import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'Vocational/questionnaire_screen.dart';
import 'Vocational/chefLv01.dart';
import 'auth_service.dart';
import 'firebase_config.dart';
import 'services/firebase_service.dart';
import 'services/game_results_service.dart';
import 'services/module_progress_service.dart';
import 'models/student_model.dart';
import 'debug_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with proper error handling
  try {
    await FirebaseConfig.initializeFirebase();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    // App will continue without Firebase
  }
  
  // Allow both orientations (games will set their preferred orientation)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Dashboard',
      theme: ThemeData.dark(),
      home: StudentDashboard(),
      routes: {
        '/student/job-role-simulation': (_) => QuestionnaireScreen(),
        '/student/chef-level-01': (_) => KitchenLearningGame(),
        // TODO: Add navigation routes like:
        // '/student/life-skills': (_) => LifeSkillsScreen(),
      },
    );
  }
}

class Module {
  final String key;
  final String title;
  final String description;
  final Color headerColor;
  final Color headerColorLight;
  final String iconPath;

  Module({
    required this.key,
    required this.title,
    required this.description,
    required this.headerColor,
    required this.headerColorLight,
    required this.iconPath,
  });
}

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  // Background image path - change this to your background image file name
  static const String backgroundImagePath = "assets/background.jpg";

  late AnimationController _bannerAnimationController;
  late Animation<double> _bannerScaleAnimation;
  
  // Auth service instance
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _bannerAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _bannerScaleAnimation =
        Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bannerAnimationController, curve: Curves.elasticOut),
    );

    // Start the pop animation loop
    _startBannerAnimation();
  }

  void _startBannerAnimation() {
    _bannerAnimationController.forward().then((_) {
      Future.delayed(Duration(milliseconds: 1500), () {
        if (mounted) {
          _bannerAnimationController.reverse().then((_) {
            Future.delayed(Duration(milliseconds: 500), () {
              if (mounted) {
                _startBannerAnimation();
              }
            });
          });
        }
      });
    });
  }

  Future<void> _handleLoginLogout() async {
    if (_authService.isLoggedIn) {
      // Logout
      _authService.logout();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged out successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Show login popup
      _showLoginDialog();
    }
  }

  void _showLoginDialog({bool isLoginMode = true}) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final ageController = TextEditingController();
    bool currentIsLoginMode = isLoginMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      currentIsLoginMode ? Icons.login : Icons.person_add,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentIsLoginMode ? 'Login' : 'Sign Up',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Form fields
                  if (!currentIsLoginMode) ...[
                    _buildTextField('First Name', firstNameController, Icons.person),
                    const SizedBox(height: 15),
                    _buildTextField('Last Name', lastNameController, Icons.person_outline),
                    const SizedBox(height: 15),
                    _buildTextField('Age', ageController, Icons.cake, keyboardType: TextInputType.number),
                    const SizedBox(height: 15),
                  ],
                  _buildTextField('Username', usernameController, Icons.account_circle),
                  const SizedBox(height: 15),
                  _buildTextField('Password', passwordController, Icons.lock, obscureText: true),
                  const SizedBox(height: 25),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            if (currentIsLoginMode) {
                              _performLogin(usernameController.text, passwordController.text);
                            } else {
                              await _performSignup(
                                firstNameController.text,
                                lastNameController.text,
                                ageController.text,
                                usernameController.text,
                                passwordController.text,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            currentIsLoginMode ? 'Login' : 'Sign Up',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        currentIsLoginMode = !currentIsLoginMode;
                      });
                    },
                    child: Text(
                      currentIsLoginMode ? 'Don\'t have an account? Sign Up' : 'Already have an account? Login',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool obscureText = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white),
        ),
        labelStyle: const TextStyle(color: Colors.white),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Future<void> _performLogin(String username, String password) async {
    if (username.isNotEmpty && password.isNotEmpty) {
      try {
        // Check if Firebase is initialized
        if (!FirebaseConfig.isInitialized) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Firebase is not initialized. Login temporarily disabled.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        
        Student? student = await FirebaseService().getStudentByUsername(username);
        if (student == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User not found. Please sign up first.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        final result = _authService.login(username, studentId: student.id);
        if (result['success'] as bool) {
          setState(() {});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] as String),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] as String),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login error: $e'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _performSignup(String firstName, String lastName, String age, String username, String password) async {
    if (firstName.isNotEmpty && lastName.isNotEmpty && age.isNotEmpty && username.isNotEmpty && password.isNotEmpty) {
      try {
        // Check if Firebase is initialized
        if (!FirebaseConfig.isInitialized) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Firebase is not initialized. Account creation temporarily disabled.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        
        // Check if username already exists
        Student? existingStudent = await FirebaseService().getStudentByUsername(username);
        if (existingStudent != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Username already exists! Please choose another.'),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Create new student
        Student newStudent = Student(
          firstName: firstName,
          lastName: lastName,
          age: age,
          username: username,
          createdAt: DateTime.now(),
        );

        // Save to Firebase
        String studentId = await FirebaseService().createStudent(newStudent);
        
        // Login the user with the generated document ID
        _authService.login(username, studentId: studentId);
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created successfully! Welcome, $firstName!'),
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating account: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bannerAnimationController.dispose();
    super.dispose();
  }

  final List<Module> modules = [
    Module(
      key: "life-skills",
      title: "LIFE SKILLS",
      description: "Practice daily living and decision-making skills.",
      headerColor: Color(0xFF059669),
      headerColorLight: Color(0xFF10b981),
      iconPath: "assets/life-skills-icon.png",
    ),
    Module(
      key: "job-role-simulation",
      title: "JOB SIMULATION",
      description: "Experience real-world job tasks safely.",
      headerColor: Color(0xFF2563EB),
      headerColorLight: Color(0xFF3b82f6),
      iconPath: "assets/job-simulation-icon.png",
    ),
    Module(
      key: "communication-social",
      title: "SOCIAL SKILLS",
      description: "Improve conversations & teamwork.",
      headerColor: Color(0xFF7C3AED),
      headerColorLight: Color(0xFF8b5cf6),
      iconPath: "assets/social-skills-icon.png",
    ),
    Module(
      key: "behaviour-emotional",
      title: "EMOTIONAL CONTROL",
      description: "Learn healthy emotional regulation.",
      headerColor: Color(0xFFEA580C),
      headerColorLight: Color(0xFFF97316),
      iconPath: "assets/emotional-control-icon.png",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    
    final padding = screenWidth * 0.03;
    final spacing = screenWidth * 0.02;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image Layer with fallback gradient
          Positioned.fill(
            child: Image.asset(
              backgroundImagePath,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to gradient if image doesn't exist
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueGrey.shade900,
                        Colors.black,
                        Colors.grey.shade900,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),
          ),
          // Content Layer
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
            ),
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  // User Info Bar
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade800, Colors.amber.shade900],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade700, width: 3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome, ${_authService.currentUserName ?? 'Guest'}!",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              SizedBox(height: 5),
                              Text(
                                _authService.isLoggedIn
                                    ? "Status: Logged In"
                                    : "Status: Not Logged In",
                                style: TextStyle(
                                  color: _authService.isLoggedIn
                                      ? Colors.green.shade200
                                      : Colors.red.shade200,
                                  fontSize: 14,
                                ),
                              )
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _handleLoginLogout,
                            icon: Icon(
                              _authService.isLoggedIn ? Icons.logout : Icons.qr_code,
                              size: 18,
                            ),
                            label: Text(
                              _authService.isLoggedIn ? "Logout" : "Login with QR",
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _authService.isLoggedIn
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: StadiumBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Module Grid
                  SliverPadding(
                    padding: EdgeInsets.all(padding),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: spacing * 2,
                        mainAxisSpacing: spacing * 2,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        builder: (context, index) {
                          return GamePanelCard(
                            module: modules[index],
                            onTap: () {
                              Navigator.pushNamed(context, "/student/${modules[index].key}");
                            },
                            screenWidth: screenWidth,
                            isVertical: false,
                          );
                        },
                        childCount: modules.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GamePanelCard extends StatelessWidget {
  final Module module;
  final double screenWidth;
  final bool isVertical;

  const GamePanelCard({
    super.key,
    required this.module,
    required this.screenWidth,
    required this.isVertical,
  });

  @override
  Widget build(BuildContext context) {
    final padding = screenWidth * 0.03;
    final spacing = screenWidth * 0.02;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [module.headerColor, module.headerColorLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: screenWidth * (isVertical ? 0.15 : 0.12),
            height: screenWidth * (isVertical ? 0.15 : 0.12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              module.iconPath.isNotEmpty
                  ? Image.asset(
                      module.iconPath,
                      width: screenWidth * 0.08,
                      height: screenWidth * 0.08,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: screenWidth * 0.08,
                          height: screenWidth * 0.08,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.extension,
                            size: screenWidth * 0.05,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    )
                  : Icon(
                    Icons.extension,
                    size: screenWidth * 0.08,
                    color: Colors.grey[600],
                  ),
            ),
          ),
          SizedBox(height: spacing),

          // Module Title
          Flexible(
            child: Text(
              module.title,
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: spacing),

          // Module Description
          Flexible(
            child: Text(
              module.description,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                color: Colors.white.withOpacity(0.9),
                height: screenWidth * 0.08,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
