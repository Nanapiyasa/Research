import 'package:flutter/material.dart';

class GameMenuNew extends StatefulWidget {
  final Map<String, dynamic>? questionnaireResults;

  const GameMenuNew({super.key, this.questionnaireResults});

  @override
  State<GameMenuNew> createState() => _GameMenuNewState();
}

class _GameMenuNewState extends State<GameMenuNew> {
  int totalScore = 0;
  int gamesPlayed = 0;

  final List<GameTile> games = [
    GameTile(
      title: 'Chef',
      icon: '👨‍🍳',
      color: Color(0xFFFF6B35),
      level: 1,
      progress: 0.3,
    ),
    GameTile(
      title: 'Retail',
      icon: '🛍️',
      color: Color(0xFF004E89),
      level: 1,
      progress: 0.0,
    ),
    GameTile(
      title: 'Cleaning',
      icon: '🧹',
      color: Color(0xFF1B998B),
      level: 1,
      progress: 0.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'), // Your background image
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB322E0).withOpacity(0.7), // Semi-transparent overlay
              Color(0xFF9b1bcc).withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main Content
              Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Game Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(width: 48),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Games Grid
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        return _buildGameTile(games[index]);
                      },
                    ),
                  ),

                  SizedBox(height: 100), // Space for floating widget
                ],
              ),

              // Floating Scoreboard Widget
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: _buildFloatingScoreboard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameTile(GameTile game) {
    return GestureDetector(
      onTap: () {
        _showGameDialog(game);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [game.color, game.color.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: game.color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background icon
            Positioned(
              right: -15,
              top: -15,
              child: Text(
                game.icon,
                style: TextStyle(
                  fontSize: 100,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Icon
                  Row(
                    children: [
                      Text(game.icon, style: TextStyle(fontSize: 32)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          game.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Level Badge
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(
                      'Level ${game.level}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: game.progress,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${(game.progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingScoreboard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SCOREBOARD',
            style: TextStyle(
              color: Color(0xFFB322E0),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreItem(
                'Total Score',
                totalScore.toString(),
                Color(0xFFFF6B35),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              _buildScoreItem(
                'Games Played',
                gamesPlayed.toString(),
                Color(0xFF004E89),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showGameDialog(GameTile game) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: game.color,
          title: Row(
            children: [
              Text(game.icon, style: TextStyle(fontSize: 32)),
              SizedBox(width: 10),
              Text(
                game.title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level: ${game.level}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Progress: ${(game.progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Game coming soon!',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class GameTile {
  final String title;
  final String icon;
  final Color color;
  final int level;
  final double progress;

  GameTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.level,
    required this.progress,
  });
}