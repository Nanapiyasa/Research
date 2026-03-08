import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'down_syndrome_detection_page.dart';
import 'flip_card_game_widget.dart';
import 'sel_game_widget.dart';
import 'sel_chatbot_widget.dart';
import 'ml_intervention_model.dart';
import 'ml_intervention_game.dart';

class HomeDashboard extends StatefulWidget {
  @override
  _HomeDashboardState createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userName = "User";

  // Theme colors
  final Color primaryPurple = Color(0xFF6B4E71);
  final Color secondaryPurple = Color(0xFF9B7B9E);
  final Color lightPurple = Color(0xFFE6D7E8);
  final Color darkPurple = Color(0xFF4A2C4E);
  final Color accentPurple = Color(0xFFB392BC);

  @override
  void initState() {
    super.initState();
    _getUserName();
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
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showGameSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Choose Game Type',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: GameType.values.length,
              itemBuilder: (context, index) {
                final gameType = GameType.values[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: gameType.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(gameType.icon, color: gameType.color, size: 24),
                    ),
                    title: Text(
                      gameType.displayName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _getGameDescription(gameType),
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: Text(gameType.displayName),
                              backgroundColor: gameType.color,
                            ),
                            body: MLInterventionGame(
                              apiUrl: 'http://10.0.2.2:5000/api/ml',
                              gameType: gameType,
                              onPredictionComplete: (result) {
                                // Handle prediction result
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Intervention needed: ${result.needsIntervention ? "Yes" : "No"}',
                                    ),
                                    backgroundColor: result.probabilityColor,
                                    duration: Duration(seconds: 3),
                                  ),
                                );

                                // Show detailed result dialog
                                _showPredictionResultDialog(result);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  String _getGameDescription(GameType gameType) {
    switch (gameType) {
      case GameType.memoryMatch:
        return 'Match pairs of cards to test your memory';
      case GameType.patternRecognition:
        return 'Remember and repeat color patterns';
      case GameType.sequenceMemory:
        return 'Recall number sequences in order';
      case GameType.reactionTime:
        return 'Test your reaction speed';
      case GameType.problemSolving:
        return 'Solve puzzles and challenges';
      default:
        return '';
    }
  }

  void _showPredictionResultDialog(MLPredictionResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                result.needsIntervention ? Icons.warning : Icons.check_circle,
                color: result.probabilityColor,
                size: 24,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.needsIntervention ? 'Intervention Needed' : 'On Track',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: result.probabilityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Intervention Probability',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        SizedBox(height: 4),
                        Text(
                          result.probabilityText,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: result.probabilityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Recommendation',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        result.recommendation,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightPurple,
              Colors.white,
              lightPurple.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Welcome and Logout
              _buildHeader(),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Stats Card
                        _buildQuickStats(),

                        SizedBox(height: 25),

                        // Main Menu Title
                        Text(
                          'Main Menu',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: darkPurple,
                          ),
                        ),

                        SizedBox(height: 15),

                        // Menu Grid
                        _buildMenuGrid(),

                        SizedBox(height: 25),

                        // Recent Activity Section
                        _buildRecentActivity(),

                        SizedBox(height: 20),

                        // Tips Section
                        _buildTipsSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: primaryPurple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: darkPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 30,
              color: primaryPurple,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: primaryPurple),
              SizedBox(width: 8),
              Text(
                "Today's Progress",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkPurple,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCircle('0', 'Games', Icons.sports_esports),
              _buildStatCircle('0', 'Score', Icons.score),
              _buildStatCircle('0', 'Streak', Icons.whatshot),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCircle(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: lightPurple,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryPurple),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkPurple,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.1,
      children: [
        // SEL Game Card
        _buildMenuCard(
          'SEL Game',
          Icons.emoji_emotions,
          Colors.orange,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('Social-Emotional Learning'),
                    backgroundColor: Colors.orange.shade900,
                  ),
                  body: SELGameWidget(
                    apiUrl: 'http://10.0.2.2:5000/api/sel',
                    onGameComplete: (stats, level) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: Text('SEL Chatbot'),
                              backgroundColor: Colors.teal.shade900,
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
          },
        ),

        // ML Intervention Card
        _buildMenuCard(
          'ML Intervention',
          Icons.analytics,
          Colors.teal,
          _showGameSelectionDialog,
        ),

        // Live Detection Card
        _buildMenuCard(
          'Live Detection',
          Icons.sensors,
          Colors.blue,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DownSyndromeDetectionPage()),
            );
          },
        ),

        // Memory Game Card
        _buildMenuCard(
          'Memory Game',
          Icons.psychology,
          Colors.purple,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('Memory Game'),
                    backgroundColor: Colors.purple.shade900,
                  ),
                  body: FlipCardGameWidget(
                    onGameComplete: (memoryScore, reactionTime) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Game Complete! Score: $memoryScore'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),

        // History Card
        _buildMenuCard(
          'History',
          Icons.history,
          Colors.orange,
              () {
            _showComingSoon('History View');
          },
        ),

        // Reports Card
        _buildMenuCard(
          'Reports',
          Icons.bar_chart,
          Colors.green,
              () {
            _showComingSoon('Reports');
          },
        ),

        // Profile Card
        _buildMenuCard(
          'Profile',
          Icons.person,
          Colors.teal,
              () {
            _showComingSoon('Profile Settings');
          },
        ),

        // Help Card
        _buildMenuCard(
          'Help',
          Icons.help,
          Colors.red,
              () {
            _showComingSoon('Help & Support');
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 35,
                color: color,
              ),
            ),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: primaryPurple, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkPurple,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          _buildActivityItem(
            'Memory Game',
            'No games played yet',
            Icons.psychology,
            Colors.purple,
          ),
          Divider(),
          _buildActivityItem(
            'SEL Game',
            'No sessions recorded',
            Icons.emoji_emotions,
            Colors.orange,
          ),
          Divider(),
          _buildActivityItem(
            'ML Intervention',
            'No sessions recorded',
            Icons.analytics,
            Colors.teal,
          ),
          Divider(),
          _buildActivityItem(
            'Detection Session',
            'No sessions recorded',
            Icons.sensors,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryPurple, secondaryPurple],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Tip',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Regular cognitive games help improve memory and reaction time. Try to play at least one game daily!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lightbulb,
            color: Colors.yellow,
            size: 40,
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Coming Soon'),
          content: Text('$feature feature is under development.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}