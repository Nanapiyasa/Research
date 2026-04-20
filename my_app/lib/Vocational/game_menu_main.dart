import 'package:flutter/material.dart';
import 'fruit_salad_level01_screen.dart';
import 'tea_level1_game.dart';

class GameMenuMain extends StatefulWidget {
  final Map<String, dynamic>? questionnaireResults;
  final String? predictedModule;

  const GameMenuMain({super.key, this.questionnaireResults, this.predictedModule});

  @override
  State<GameMenuMain> createState() => _GameMenuMainState();
}

class _GameMenuMainState extends State<GameMenuMain> {
  int totalScore = 0;
  int gamesPlayed = 0;

  final List<GameTile> games = [
    GameTile(
      title: 'Fruit Salad',
      icon: '🥗',
      color: Color(0xFFFF6B35),
      level: 1,
      progress: 0.3,
    ),
    GameTile(
      title: 'Tea',
      icon: '🍵',
      color: Color(0xFF004E89),
      level: 1,
      progress: 0.0,
    ),
    GameTile(
      title: 'Pastry',
      icon: '🥐',
      color: Color(0xFF1B998B),
      level: 1,
      progress: 0.0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _showRecommendationIfNeeded();
  }

  void _showRecommendationIfNeeded() {
    if (widget.predictedModule != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRecommendationDialog(widget.predictedModule!);
      });
    }
  }

  void _showRecommendationDialog(String recommendedModule) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🎯 Recommended Module'),
          content: Text('Based on your questionnaire, we recommend starting with the $recommendedModule module!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
          image: DecorationImage(
            image: AssetImage('assets/LevelBackground.png'), // Your background image
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
                          'Choose Your Quest',
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
        if (game.title == 'Fruit Salad') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FruitSaladLevel01Screen()),
          );
        } else if (game.title == 'Tea') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TeaLevel1Game()),
          );
        } else {
          _showGameDialog(game);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              game.color,
              game.color.withValues(alpha: 0.85),
              game.color.withValues(alpha: 0.7),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: game.color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Center(
                  child: Text(
                    game.icon,
                    style: TextStyle(
                      fontSize: 60,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          game.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          game.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(1, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Level ${game.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Progress Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(game.progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: game.progress,
                            minHeight: 6,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Shimmer effect
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
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