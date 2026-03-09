import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'fruit_match_level2.dart';

class FruitMatchGame extends StatelessWidget {
  const FruitMatchGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Match the Ripe Fruits',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const LandscapeGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LandscapeGame extends StatelessWidget {
  const LandscapeGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return const GameScreen();
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late List<Fruit> fruits;
  late Fruit targetFruit;
  late List<Fruit> options;
  int score = 0;
  int lives = 3;
  int levelScoreLimit = 100;
  bool isAnswered = false;
  String? selectedFruitName;
  bool isCorrect = false;
  late AnimationController _scaleController;
  late AnimationController _questionAnimationController;
  late Animation<double> _questionScaleAnimation;
  
  // Timer variables
  int _seconds = 0;
  Timer? _timer;
  
  // Animation for level complete dialog
  late AnimationController _dialogAnimationController;
  late Animation<double> _dialogScaleAnimation;
  
  // Confetti controller
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _initializeFruits();
    
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    // Initialize dialog animation controller
    _dialogAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _dialogScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dialogAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _questionScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.linear,
    ));

    _generateNewRound();
    _startQuestionAnimation();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++; // Count up
      });
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _questionAnimationController.dispose();
    _dialogAnimationController.dispose();
    _confettiController.dispose();
    _timer?.cancel(); // Cancel timer
    super.dispose();
  }

  void _initializeFruits() {
    fruits = [
      Fruit(name: 'Ripe Papaya', assetPath: 'assets/Ripe Papaya.png'),
      Fruit(name: 'Ripe Yellow Mango', assetPath: 'assets/Ripe Mango.png'),
      Fruit(name: 'Ripe Banana', assetPath: 'assets/Ripe Banana.png'),
      Fruit(name: 'Half ripe Papaya', assetPath: 'assets/Half ripe.png'),
      Fruit(name: 'Unripe Papaya dark', assetPath: 'assets/Unripe papaya dark.png'),
      Fruit(name: 'Unripe Mango', assetPath: 'assets/Unripe Mango .png'),
      Fruit(name: 'Unripe Banana', assetPath: 'assets/Unripe Banana.png'),
    ];
  }

  void _startQuestionAnimation() {
    _questionAnimationController.repeat(reverse: true);
  }

  void _generateNewRound() {
    final correctRipeFruits = fruits.where((f) => 
        f.name == 'Ripe Papaya' || 
        f.name == 'Ripe Yellow Mango' || 
        f.name == 'Ripe Banana'
    ).toList();
    
    targetFruit = correctRipeFruits[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % correctRipeFruits.length];
    
    options = [];
    options.add(targetFruit);
    
    // Add 3 random incorrect options for 2x2 grid (1 correct + 3 incorrect = 4 total)
    final incorrectFruits = fruits.where((f) => 
        f.name != 'Ripe Papaya' && 
        f.name != 'Ripe Yellow Mango' && 
        f.name != 'Ripe Banana'
    ).toList();
    
    incorrectFruits.shuffle();
    for (int i = 0; i < 3; i++) {
      if (i < incorrectFruits.length) {
        options.add(incorrectFruits[i]);
      }
    }
    
    options.shuffle();
    isAnswered = false;
    selectedFruitName = null;
    isCorrect = false;
  }

  void _handleFruitSelection(Fruit selectedFruit) {
    if (isAnswered) return;

    setState(() {
      isAnswered = true;
      selectedFruitName = selectedFruit.name;
      isCorrect = selectedFruit.name == targetFruit.name;
    });

    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    if (isCorrect) {
      setState(() => score += 10);
      
      // Trigger confetti for correct answer
      _confettiController.play();
      
      if (score >= levelScoreLimit) {
        _showLevelCompleteDialog();
      } else {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _generateNewRound());
          }
        });
      }
    } else {
      setState(() => lives--);
      
      if (lives <= 0) {
        _showGameOverDialog();
      } else {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _generateNewRound());
          }
        });
      }
    }
  }

  void _showLevelCompleteDialog() {
    _dialogAnimationController.forward();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ScaleTransition(
          scale: _dialogScaleAnimation,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
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
                  const Text(
                    '🎉 Level 1 Complete!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Amazing! You scored $score points!',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Ready for Level 2?",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 3),
                  // Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Play Again Button
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            score = 0;
                            lives = 3;
                            _generateNewRound();
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white),
                          ),
                        ),
                        child: const Text(
                          "Play Again",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Let's Go Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FruitMatchLevel2Game(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Let's Go!",
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over!'),
        content: Text('Final Score: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                score = 0;
                lives = 3;
                _generateNewRound();
              });
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Kitchen background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kitchen1.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    // Small screen - vertical layout
                    return Column(
                      children: [
                        // Top bar with title - Tea game style
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 400) {
                                // Small screen - vertical layout
                                return Column(
                                  children: [
                                    const Text(
                                      'Fruit Matching',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildCompactStatItem('Score', score.toString()),
                                        const SizedBox(width: 16),
                                        _buildCompactTimer(),
                                        const SizedBox(width: 16),
                                        _buildCompactStatItem('Lives', lives.toString()),
                                      ],
                                    ),
                                  ],
                                );
                              } else {
                                // Large screen - horizontal layout
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Fruit Matching - Level 1',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    _buildTimer(),
                                    Row(
                                      children: [
                                        _buildStatItem('Score', score.toString()),
                                        const SizedBox(width: 16),
                                        _buildStatItem('Lives', lives.toString()),
                                      ],
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ),
                        // Main content area
                        Expanded(
                          child: Column(
                            children: [
                              // Fruit display area (math area)
                              Expanded(
                                flex: 2,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 5),
                                    _buildQuestionCard(),
                                  ],
                                ),
                              ),
                              // Answer options area
                              Expanded(
                                flex: 3,
                                child: _buildOptionsGrid(isSmallScreen: true),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Large screen - horizontal layout
                    return Column(
                      children: [
                        // Top bar with title - Tea game style
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 400) {
                                // Small screen - vertical layout
                                return Column(
                                  children: [
                                    const Text(
                                      'Fruit Matching',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildCompactStatItem('Score', score.toString()),
                                        const SizedBox(width: 16),
                                        _buildCompactTimer(),
                                        const SizedBox(width: 16),
                                        _buildCompactStatItem('Lives', lives.toString()),
                                      ],
                                    ),
                                  ],
                                );
                              } else {
                                // Large screen - horizontal layout
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Fruit Matching',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    _buildTimer(),
                                    Row(
                                      children: [
                                        _buildStatItem('Score', score.toString()),
                                        const SizedBox(width: 16),
                                        _buildStatItem('Lives', lives.toString()),
                                      ],
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ),
                        // Main content area
                        Expanded(
                          child: Row(
                            children: [
                              // Left side - Fruit display (math area)
                              Expanded(
                                flex: 1,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Find the Ripe Fruit',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildQuestionCard(),
                                  ],
                                ),
                              ),
                              // Right side - Answer options
                              Expanded(
                                flex: 1,
                                child: _buildOptionsGrid(isSmallScreen: false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2, // downward direction
              blastDirectionality: BlastDirectionality.directional,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return ScaleTransition(
      scale: _questionScaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  targetFruit.assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 40, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsGrid({required bool isSmallScreen}) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const ScrollPhysics(), // Enable scrolling
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Always 2x2 grid
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 0.8,
        ),
        itemCount: math.min(4, options.length), // Ensure max 4 items for 2x2 grid
        itemBuilder: (context, index) {
          final fruit = options[index];
          final isSelected = selectedFruitName == fruit.name;
          
          return ScaleTransition(
            scale: isSelected
                ? Tween(begin: 1.0, end: 1.05).animate(
                    _scaleController,
                  )
                : AlwaysStoppedAnimation(1.0),
            child: GestureDetector(
              onTap: () => _handleFruitSelection(fruit),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isCorrect
                          ? Colors.green
                          : Colors.red)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.black12,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: isSelected
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.grey.shade50,
                                  ],
                                ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            fruit.assetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.image, size: 30, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          fruit.name,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${_seconds}s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '${_seconds}s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class Fruit {
  final String name;
  final String assetPath;

  Fruit({required this.name, required this.assetPath});
}
