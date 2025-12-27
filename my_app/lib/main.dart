import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'questionnaire_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set orientation to landscape only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Dashboard',
      theme: ThemeData.dark(),
      home: StudentDashboard(),
      routes: {
        '/module-selection': (_) => ModuleSelectionPage(),
        '/student/job-role-simulation': (_) => QuestionnaireScreen(),
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
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Background image path - change this to your background image file name
  static const String backgroundImagePath = "assets/background.jpeg";

  @override
  void initState() {
    super.initState();
    // Initialize animation controller for pop in/out effect
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    // Create scale animation that goes from 1.0 to 1.15 and back
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation and make it repeat
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image Layer with fallback gradient
          Positioned.fill(
            child: Image.asset(
              backgroundImagePath,
              fit: BoxFit.cover,
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
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              // Semi-transparent overlay to ensure text readability
              color: Colors.black.withOpacity(0.3),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// User Info Bar
                  Container(
                    padding: EdgeInsets.all(16),
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
                              "Welcome, Player One!",
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Role: Student",
                              style: TextStyle(color: Colors.amber.shade200),
                            )
                          ],
                        ),

                        /// Logout Button
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Add logout logic
                          },
                          icon: Icon(Icons.logout, size: 20),
                          label: Text("Logout"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: StadiumBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40),

                  /// Animated Title Banner Button
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ModuleSelectionPage(),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.yellow.shade400, Colors.amber.shade500],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.yellow.shade600, width: 3),
                                ),
                                child: Text(
                                  "CHOOSE YOUR QUEST",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),
                              Text(
                                "Tap to select a learning module",
                                style: TextStyle(color: Colors.white70, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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

class ModuleSelectionPage extends StatelessWidget {
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

  // Background image path - change this to your background image file name
  static const String backgroundImagePath = "assets/background.jpeg";

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Calculate responsive values
    final crossAxisCount = 2; // Always 2 columns for 2x2 grid
    final spacing = screenWidth * 0.02; // 2% of screen width
    final padding = screenWidth * 0.03; // 3% of screen width
    
    // Aspect ratio for 2x2 grid in landscape
    final aspectRatio = 1.1;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background Image Layer with fallback gradient
          Positioned.fill(
            child: Image.asset(
              backgroundImagePath,
              fit: BoxFit.cover,
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
              // Semi-transparent overlay to ensure text readability
              color: Colors.black.withOpacity(0.3),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Back button
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: screenWidth * 0.04,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Select Your Module",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.025,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Game Panel Grid
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: aspectRatio,
                      padding: EdgeInsets.symmetric(horizontal: spacing),
                      children: modules.map((m) {
                        return GamePanelCard(
                          module: m,
                          onTap: () {
                            Navigator.pushNamed(context, "/student/${m.key}");
                          },
                          screenWidth: screenWidth,
                        );
                      }).toList(),
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

  const GamePanelCard({
    required this.module,
    required this.onTap,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive sizing based on screen width
    final iconSize = screenWidth * 0.08; // 8% of screen width
    final padding = screenWidth * 0.02; // 2% of screen width
    final borderRadius = screenWidth * 0.02;
    final titleFontSize = screenWidth * 0.022;
    final descriptionFontSize = screenWidth * 0.015;
    
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
        ),
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image with error handling
            Image.asset(
              module.iconPath,
              height: iconSize,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if image fails to load
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
