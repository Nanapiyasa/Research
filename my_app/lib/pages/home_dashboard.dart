import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui'; // For ImageFilter
import 'down_syndrome_detection_page.dart';
import 'flip_card_game_widget.dart';
import 'sel_game_widget.dart';
import 'sel_chatbot_widget.dart';
import 'ml_intervention_game.dart';
// Import your login page - adjust the path if needed
import 'package:NewApp/main.dart'; // Make sure this path is correct

class HomeDashboard extends StatefulWidget {
  @override
  _HomeDashboardState createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userName = "User";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Modern vibrant color palette (matching Login/Registration)
  final Color primaryPurple = Color(0xFF6B4EFF); // Electric Purple
  final Color secondaryBlue = Color(0xFF4A90E2); // Ocean Blue
  final Color accentPink = Color(0xFFFF6B9D); // Vibrant Pink
  final Color accentTeal = Color(0xFF20C997); // Mint Teal
  final Color accentOrange = Color(0xFFFFA36B); // Soft Orange
  final Color deepPurple = Color(0xFF3832A0); // Deep Indigo
  final Color lightPurple = Color(0xFF9D8CFF); // Light Purple
  final Color bgLight = Color(0xFFF8F9FF); // Off White with purple tint
  final Color cardBg = Colors.white;
  final Color textPrimary = Color(0xFF2D3748); // Dark Gray
  final Color textSecondary = Color(0xFF718096); // Medium Gray
  final Color successGreen = Color(0xFF48BB78); // Success Green

  // Game-specific colors
  final Color socialColor = Color(0xFFFF6B9D); // Pink
  final Color cognitiveColor = Color(0xFF6B4EFF); // Purple
  final Color downSyndromeColor = Color(0xFF20C997); // Teal
  final Color memoryColor = Color(0xFFFFA36B); // Orange

  @override
  void initState() {
    super.initState();
    _getUserName();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _getUserName() {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? user.email?.split('@').first ?? 'User';
      });
    }
  }

  Future<void> _logout() async {
    try {
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
                    'Logging Out',
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

      await _auth.signOut();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Navigate to login page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(),
          ),
        );

        // Show modern snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Logged out successfully')),
              ],
            ),
            backgroundColor: successGreen,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Error logging out: $e')),
            ],
          ),
          backgroundColor: accentPink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Exit App',
              style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold),
            ),
            content: Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'No',
                  style: TextStyle(color: textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Yes', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
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
            child: Column(
              children: [
                _buildModernHeader(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgLight,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: bgLight.withOpacity(0.9),
                          child: SingleChildScrollView(
                            physics: BouncingScrollPhysics(),
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildModernSectionHeader('Learning Dashboard', Icons.dashboard_customize),
                                    SizedBox(height: 16),
                                    _buildModernMenuGrid(),

                                    SizedBox(height: 20),

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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Animated profile section
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.white.withOpacity(0.3), Colors.transparent],
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.white, accentPink],
                ),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person_outline,
                  size: 28,
                  color: primaryPurple,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Modern logout button
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.white.withOpacity(0.2), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPurple, accentPink],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: primaryPurple.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = LinearGradient(
                colors: [primaryPurple, accentPink],
              ).createShader(Rect.fromLTWH(0, 0, 200, 25)),
          ),
        ),
      ],
    );
  }

  Widget _buildModernMenuGrid() {
    List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Social-Emotional',
        'subtitle': 'Build emotional intelligence',
        'icon': Icons.emoji_emotions,
        'gradient': [accentPink, Color(0xFFFF4D6D)],
        'route': () => _navigateToSELGame(),
        'stats': '8',
      },
      {
        'title': 'Cognitive Fitness',
        'subtitle': 'Problem solving & logic',
        'icon': Icons.psychology,
        'gradient': [primaryPurple, deepPurple],
        'route': () => _navigateToMLGame(),
        'stats': '5',
      },
      {
        'title': 'Down Syndrome',
        'subtitle': 'Specialized learning',
        'icon': Icons.favorite,
        'gradient': [accentTeal, Color(0xFF0FB2A8)],
        'route': () => _navigateToDownSyndromeDetection(),
        'stats': '12',
      },

    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85, // Adjusted to prevent overflow
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        return _buildModernMenuCard(menuItems[index]);
      },
    );
  }

  Widget _buildModernMenuCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: item['route'],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [item['gradient'][0], item['gradient'][1]],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: item['gradient'][0].withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative pattern
            Positioned(
              bottom: -15,
              right: -15,
              child: Icon(
                item['icon'],
                size: 70,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon and stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item['icon'],
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['stats'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  // Title
                  Text(
                    item['title'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 2),

                  // Subtitle
                  Text(
                    item['subtitle'],
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 6),

                  // Start button
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.white, size: 10),
                        SizedBox(width: 2),
                        Text(
                          'Start',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }




  Widget _buildProgressIndicator(String label, double value, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(
                value: value,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 5,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }


  void _navigateToSELGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              'Social-Emotional Learning',
              style: TextStyle(
                fontSize: 18,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [accentPink, Colors.white],
                  ).createShader(Rect.fromLTWH(0, 0, 200, 30)),
              ),
            ),
            backgroundColor: accentPink,
            elevation: 0,
            leading: Container(
              margin: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          body: SELGameWidget(
            apiUrl: 'http://10.0.2.2:5000/api/sel',
            onGameComplete: (stats, level) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text(
                        'SEL Chatbot',
                        style: TextStyle(
                          fontSize: 18,
                          foreground: Paint()
                            ..shader = LinearGradient(
                              colors: [accentTeal, Colors.white],
                            ).createShader(Rect.fromLTWH(0, 0, 150, 30)),
                        ),
                      ),
                      backgroundColor: accentTeal,
                      elevation: 0,
                      leading: Container(
                        margin: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    body: SELChatbotWidget(
                      apiUrl: 'http://10.0.2.2:5000/api/sel',
                      userLevel: level,
                      userStats: stats,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToMLGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MLInterventionGame(
          apiUrl: 'http://10.0.2.2:5000/api/ml',
          onPredictionComplete: (result) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Expanded(child: Text('Mission analysis complete!', style: TextStyle(fontSize: 14))),
                  ],
                ),
                backgroundColor: result.probabilityColor ?? primaryPurple,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: EdgeInsets.all(12),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToMemoryGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              'Memory Game',
              style: TextStyle(
                fontSize: 18,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [accentOrange, Colors.white],
                  ).createShader(Rect.fromLTWH(0, 0, 150, 30)),
              ),
            ),
            backgroundColor: accentOrange,
            elevation: 0,
            leading: Container(
              margin: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          body: FlipCardGameWidget(
            onGameComplete: (memoryScore, reactionTime) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Expanded(child: Text('Game Complete! Score: $memoryScore', style: TextStyle(fontSize: 14))),
                    ],
                  ),
                  backgroundColor: successGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  margin: EdgeInsets.all(12),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToDownSyndromeDetection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DownSyndromeDetectionPage(),
      ),
    );
  }
}