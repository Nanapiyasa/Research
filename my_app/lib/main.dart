import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'questionnaire_screen.dart';
import 'auth_service.dart';
import 'Vocational/chefLv01.dart';
import 'loading_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      // Login with QR code
      final result = await _authService.scanAndLogin();
      if (result['success'] as bool) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
                  // CHOOSE YOUR QUEST Title
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _bannerScaleAnimation,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            margin: EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.yellow.shade400, Colors.amber.shade500],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.yellow.shade600, width: 3),
                            ),
                            child: Text(
                              "CHOOSE YOUR QUEST",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                  // Module Grid
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: spacing),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: spacing * 2,
                        mainAxisSpacing: spacing * 2,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
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
  final VoidCallback onTap;
  final double screenWidth;
  final bool isVertical;

  const GamePanelCard({super.key, 
    required this.module,
    required this.onTap,
    required this.screenWidth,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive sizing based on screen width
    final iconSize = isVertical ? screenWidth * 0.19 : screenWidth * 0.16;
    final padding = screenWidth * 0.03;
    final borderRadius = screenWidth * 0.03;
    final titleFontSize = isVertical ? screenWidth * 0.05 : screenWidth * 0.035;
    final descriptionFontSize = isVertical ? screenWidth * 0.04 : screenWidth * 0.025;
    
    return InkWell(
      borderRadius: BorderRadius.circular(borderRadius),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [module.headerColor, module.headerColorLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(padding),
        child: isVertical
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image with error handling
                  Image.asset(
                    module.iconPath,
                    height: iconSize,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: iconSize,
                        width: iconSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white70,
                          size: iconSize * 0.6,
                        ),
                      );
                    },
                  ),
                  SizedBox(width: padding),
                  // Text content
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: padding * 0.4),
                        Text(
                          module.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: descriptionFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: padding * 0.5),
                  Icon(Icons.arrow_forward, color: Colors.white, size: iconSize * 0.8),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image with error handling
                  Image.asset(
                    module.iconPath,
                    height: iconSize,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: iconSize,
                        width: iconSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white70,
                          size: iconSize * 0.6,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: padding * 0.6),
                  Flexible(
                    child: Text(
                      module.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: padding * 0.5),
                  Flexible(
                    child: Text(
                      module.description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: descriptionFontSize,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
