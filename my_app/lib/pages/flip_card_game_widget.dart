import 'dart:async';
import 'package:flutter/material.dart';
import 'flip_card_game.dart';

class FlipCardGameWidget extends StatefulWidget {
  final Function(int memoryScore, int reactionTime) onGameComplete;

  const FlipCardGameWidget({
    Key? key,
    required this.onGameComplete,
  }) : super(key: key);

  @override
  _FlipCardGameWidgetState createState() => _FlipCardGameWidgetState();
}

class _FlipCardGameWidgetState extends State<FlipCardGameWidget> with SingleTickerProviderStateMixin {
  late List<CardItem> cards;
  late GameStats stats;
  int? firstSelectedIndex;
  bool isWaiting = false;
  late AnimationController _flipController;
  Timer? _gameTimer;

  // Selected level
  GameLevel _selectedLevel = GameLevel.easy;
  bool _showLevelSelection = true;

  // Emojis for cards (expanded for higher levels)
  final List<String> emojis = [
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', // Animals
    '🐨', '🐯', '🦁', '🐮', '🦒', '🦘', '🐧', '🐦', // More animals
    '🐟', '🐠', '🐡', '🐙', // Sea creatures
  ];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  void _startGame(GameLevel level) {
    _selectedLevel = level;
    _initializeGame();
    setState(() {
      _showLevelSelection = false;
    });
  }

  void _initializeGame() {
    // Create pairs of cards based on selected level
    List<CardItem> newCards = [];
    int pairCount = _selectedLevel.cardCount ~/ 2;

    for (int i = 0; i < pairCount; i++) {
      for (int j = 0; j < 2; j++) { // Two cards per pair
        newCards.add(CardItem(
          id: newCards.length,
          emoji: emojis[i % emojis.length],
          pairId: i,
          isFlipped: false,
          isMatched: false,
        ));
      }
    }

    // Shuffle cards
    newCards.shuffle();

    setState(() {
      cards = newCards;
      stats = GameStats(
        startTime: DateTime.now(),
        level: _selectedLevel,
        levelBonus: _selectedLevel.timeBonus,
      );
      firstSelectedIndex = null;
    });

    // Start game timer
    _gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted && !_allCardsMatched()) {
        setState(() {
          stats.totalTime = DateTime.now().difference(stats.startTime);
        });
      }
    });
  }

  bool _allCardsMatched() {
    return cards.every((card) => card.isMatched);
  }

  void _onCardTap(int index) {
    if (isWaiting) return;
    if (cards[index].isMatched) return;
    if (firstSelectedIndex == index) return;

    // Record reaction time for this move
    final reactionTime = DateTime.now().difference(stats.startTime);

    setState(() {
      stats.reactionTimes.add(reactionTime);
      cards[index].isFlipped = true;
      stats.moves++;
    });

    if (firstSelectedIndex == null) {
      // First card selected
      firstSelectedIndex = index;
    } else {
      // Second card selected - check for match
      _checkMatch(index);
    }
  }

  void _checkMatch(int secondIndex) {
    final firstCard = cards[firstSelectedIndex!];
    final secondCard = cards[secondIndex];

    if (firstCard.pairId == secondCard.pairId) {
      // Match found
      setState(() {
        firstCard.isMatched = true;
        secondCard.isMatched = true;
        stats.matches++;

        firstSelectedIndex = null;
      });

      // Check if game is complete
      if (_allCardsMatched()) {
        _completeGame();
      }
    } else {
      // No match
      isWaiting = true;

      // Flip cards back after delay
      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            firstCard.isFlipped = false;
            secondCard.isFlipped = false;
            firstSelectedIndex = null;
            isWaiting = false;
          });
        }
      });
    }
  }

  void _completeGame() {
    _gameTimer?.cancel();

    final memoryScore = stats.calculateMemoryScore();
    final reactionTime = stats.averageReactionTime;

    // Show completion dialog with level details
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber),
              SizedBox(width: 8),
              Text('Level Complete! 🎉'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedLevel.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedLevel.displayName,
                    style: TextStyle(
                      color: _selectedLevel.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                _buildResultRow('Memory Score', '$memoryScore', Icons.memory, Colors.purple),
                SizedBox(height: 8),
                _buildResultRow('Reaction Time', '${reactionTime}ms', Icons.timer, Colors.blue),
                SizedBox(height: 8),
                _buildResultRow('Moves', '${stats.moves}', Icons.compare_arrows, Colors.orange),
                SizedBox(height: 8),
                _buildResultRow('Matches', '${stats.matches}', Icons.check_circle, Colors.green),
                SizedBox(height: 8),
                _buildResultRow('Time', '${stats.totalTime.inSeconds}s', Icons.access_time, Colors.teal),
                SizedBox(height: 8),
                _buildResultRow('Level Bonus', '+${_selectedLevel.timeBonus}', Icons.star, Colors.amber),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onGameComplete(memoryScore, reactionTime);
              },
              child: Text('Submit Score'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _playAgain();
              },
              child: Text('Play Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _showLevelSelection = true;
                });
              },
              child: Text('Change Level'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Spacer(),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  void _playAgain() {
    _gameTimer?.cancel();
    _initializeGame();
  }

  void _goBackToLevelSelection() {
    _gameTimer?.cancel();
    setState(() {
      _showLevelSelection = true;
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showLevelSelection) {
      return _buildLevelSelectionScreen();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple.shade100, Colors.blue.shade100],
        ),
      ),
      child: Column(
        children: [
          // Game Header with Stats and Level Info
          _buildGameHeader(),

          // Game Grid
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _getGridColumns(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.9,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return _buildCard(cards[index], index);
                },
              ),
            ),
          ),

          // Game Controls
          _buildGameControls(),
        ],
      ),
    );
  }

  int _getGridColumns() {
    switch (_selectedLevel) {
      case GameLevel.easy:
        return 4; // 4x2 grid for 8 cards
      case GameLevel.medium:
        return 4; // 4x3 grid for 12 cards
      case GameLevel.hard:
        return 4; // 4x4 grid for 16 cards
      case GameLevel.expert:
        return 5; // 5x4 grid for 20 cards
    }
  }





  Widget _buildLevelSelectionScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade100, Colors.blue.shade100],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trophy with animation
                  TweenAnimationBuilder(
                    duration: Duration(seconds: 1),
                    tween: Tween<double>(begin: 0, end: 1),
                    curve: Curves.elasticOut,
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.amber.shade50,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.emoji_events,
                            size: 60,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 15),

                  // Title
                  Text(
                    'Select Difficulty',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'Choose your challenge level',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 25),

                  // Level buttons
                  ...GameLevel.values.map((level) =>
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: _buildEnhancedLevelButton(level), // Renamed to avoid conflict
                      )
                  ).toList(),

                  SizedBox(height: 20),

                  // Back button with better styling
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back, size: 18),
                      label: Text(
                        'Back to Main Menu',
                        style: TextStyle(fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.purple.shade700,
                        side: BorderSide(color: Colors.purple.shade200, width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // Extra bottom padding for scrolling
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Renamed to _buildEnhancedLevelButton to avoid conflict with existing _buildLevelButton
  Widget _buildEnhancedLevelButton(GameLevel level) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: level.color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _startGame(level),
        style: ElevatedButton.styleFrom(
          backgroundColor: level.color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Level name with icon
            Row(
              children: [
                Icon(
                  _getLevelIcon(level),
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  level.displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Card count and bonus
            Row(
              children: [
                // Card count
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.style, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '${level.cardCount}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),

                // Bonus points
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber.shade100),
                      SizedBox(width: 4),
                      Text(
                        '+${level.timeBonus}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLevelIcon(GameLevel level) {
    switch (level) {
      case GameLevel.easy:
        return Icons.sentiment_satisfied;
      case GameLevel.medium:
        return Icons.trending_up;
      case GameLevel.hard:
        return Icons.flash_on;
      case GameLevel.expert:
        return Icons.military_tech;
      default:
        return Icons.gamepad;
    }
  }




  Widget _buildLevelButton(GameLevel level) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _startGame(level),
        style: ElevatedButton.styleFrom(
          backgroundColor: level.color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              level.displayName,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Icon(Icons.style, size: 20),
                SizedBox(width: 4),
                Text('${level.cardCount} cards'),
                SizedBox(width: 16),
                Icon(Icons.star, size: 20),
                SizedBox(width: 4),
                Text('+${level.timeBonus}'),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildGameHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _selectedLevel.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stairs, color: _selectedLevel.color, size: 16),
                    SizedBox(width: 4),
                    Text(
                      _selectedLevel.displayName,
                      style: TextStyle(
                        color: _selectedLevel.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _goBackToLevelSelection,
                tooltip: 'Change Level',
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.memory,
                label: 'Memory',
                value: '${stats.calculateMemoryScore()}',
                color: Colors.purple,
              ),
              _buildStatItem(
                icon: Icons.timer,
                label: 'Reaction',
                value: '${stats.averageReactionTime}ms',
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.compare_arrows,
                label: 'Moves',
                value: '${stats.moves}',
                color: Colors.orange,
              ),
              _buildStatItem(
                icon: Icons.access_time,
                label: 'Time',
                value: '${stats.totalTime.inSeconds}s',
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildCard(CardItem card, int index) {
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: card.isMatched
              ? Colors.green.withOpacity(0.3)
              : card.isFlipped
              ? Colors.white
              : _selectedLevel.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: card.isMatched
            ? Icon(Icons.check_circle, color: Colors.green, size: 30)
            : card.isFlipped
            ? Center(
          child: Text(
            card.emoji,
            style: TextStyle(fontSize: 30),
          ),
        )
            : Center(
          child: Icon(
            Icons.help_outline,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildGameControls() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _playAgain,
            icon: Icon(Icons.refresh),
            label: Text('New Game'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _goBackToLevelSelection,
            icon: Icon(Icons.stairs),
            label: Text('Change Level'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
          if (_allCardsMatched())
            ElevatedButton.icon(
              onPressed: _completeGame,
              icon: Icon(Icons.send),
              label: Text('Submit Score'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}