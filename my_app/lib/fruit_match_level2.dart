import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'fruit_match_level3.dart';

class FruitMatchLevel2Game extends StatelessWidget {
  const FruitMatchLevel2Game({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fruit Salad Preparation - Level 2',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const LandscapeGameLevel2(),
    );
  }
}

class LandscapeGameLevel2 extends StatelessWidget {
  const LandscapeGameLevel2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return const GameScreenLevel2();
  }
}

class GameScreenLevel2 extends StatefulWidget {
  const GameScreenLevel2({Key? key}) : super(key: key);

  @override
  State<GameScreenLevel2> createState() => _GameScreenLevel2State();
}

class _GameScreenLevel2State extends State<GameScreenLevel2> with TickerProviderStateMixin {
  // Fruits for level 2
  List<FruitLevel2> allFruits = [];
  List<FruitLevel2> currentDisplayFruits = [];
  int currentStep = 1; // 1, 2, or 3
  int score = 0;
  int lives = 3;
  int _seconds = 0;
  Timer? _timer;
  
  // Confetti controller
  late ConfettiController _confettiController;
  
  // Animation controller for knife
  late AnimationController _knifeAnimationController;
  late Animation<double> _knifeScaleAnimation;
  
  // Continuous knife animation
  late AnimationController _continuousKnifeAnimationController;
  late Animation<double> _continuousKnifeScaleAnimation;
  
  // Game state - show instructions or game
  bool _showInstructions = true;
  
  // Animation for instructions
  late AnimationController _instructionAnimationController;
  late Animation<double> _instructionScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    // Initialize instruction animation controller
    _instructionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _instructionScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _instructionAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // Initialize knife animation
    _knifeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _knifeScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _knifeAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // Initialize continuous knife animation
    _continuousKnifeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _continuousKnifeScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _continuousKnifeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Start continuous knife animation
    _continuousKnifeAnimationController.repeat(reverse: true);
    
    _initializeFruits();
    _startTimer();
    
    // Start instruction animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _instructionAnimationController.forward();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++; // Count up
      });
    });
  }

  void _initializeFruits() {
    // All 3 covered fruits for the 3 steps
    allFruits = [
      FruitLevel2(
        name: 'Covered Mango',
        assetPath: 'assets/Covered Mango.jpeg',
        isUncovered: false,
      ),
      FruitLevel2(
        name: 'Covered Papaya',
        assetPath: 'assets/Covered Papaw.jpeg',
        isUncovered: false,
      ),
      FruitLevel2(
        name: 'Covered Banana',
        assetPath: 'assets/Covered Banana.jpeg',
        isUncovered: false,
      ),
    ];
    
    // Start with first fruit + knife
    _setupCurrentStep();
  }

  void _setupCurrentStep() {
    if (currentStep <= 3 && currentStep - 1 < allFruits.length) {
      currentDisplayFruits = [
        allFruits[currentStep - 1], // Current fruit
        FruitLevel2(
          name: 'Knife',
          assetPath: 'assets/Knife.png',
          isKnife: true,
        ),
      ];
    }
  }

  void _handleKnifeTap() {
    // Animate knife
    _knifeAnimationController.forward().then((_) {
      _knifeAnimationController.reverse();
    });

    // Only proceed if we haven't completed all 3 steps
    if (currentStep <= 3) {
      setState(() {
        // Transform the current fruit from covered to uncovered
        if (currentStep - 1 < allFruits.length) {
          // Change the fruit from covered to uncovered
          allFruits[currentStep - 1].isUncovered = true;
          score += 10;
          
          // Trigger confetti for successful uncover
          _confettiController.play();
          
          // Wait a moment to show the transformation, then move to next step
          Future.delayed(const Duration(milliseconds: 3000), () {
            if (mounted) {
              setState(() {
                // Move to next step
                currentStep++;
                
                // Setup next step or complete level
                if (currentStep <= 3) {
                  _setupCurrentStep();
                }
              });
              
              // Show step completion popup
              _showStepCompleteDialog();
              
              // Check if all 3 steps are completed
              if (currentStep > 3) {
                Future.delayed(const Duration(milliseconds: 2000), () {
                  if (mounted) {
                    _showLevelCompleteDialog();
                  }
                });
              }
            }
          });
        }
      });
    }
  }

  void _showStepCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.deepOrange],
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
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Step Complete!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Great job! Fruit uncovered successfully!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLevelCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
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
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Level 2 Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Congratulations! You prepared the fruit salad with a score of $score!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FruitMatchLevel3Game(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Reset orientation to portrait only when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    _knifeAnimationController.dispose();
    _continuousKnifeAnimationController.dispose();
    _instructionAnimationController.dispose();
    _confettiController.dispose();
    _timer?.cancel(); // Cancel timer
    super.dispose();
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
          ),
          
          // Show instructions or game
          if (_showInstructions)
            _buildInstructionScreen()
          else
            _buildGameScreen(),
          
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

  Widget _buildInstructionScreen() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7), // Reduced brightness
      ),
      child: SafeArea(
        child: Center(
          child: ScaleTransition(
            scale: _instructionScaleAnimation,
            child: Container(
              margin: const EdgeInsets.all(30),
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
                    'Fruit Salad Level 2',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Prepare Fruit Salad',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tap the knife to uncover covered fruits',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  // Let's Go Button
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showInstructions = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      "Let's Go!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            // Small screen - vertical layout
            return Column(
              children: [
                // Top bar with title
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
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
                              'Fruit Salad - Level 2',
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
                                _buildCompactStatItem('Step', '$currentStep/3'),
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
                              'Fruit Salad - Level 2',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                _buildTimer(),
                                const SizedBox(width: 16),
                                _buildStatItem('Score', score.toString()),
                                const SizedBox(width: 16),
                                _buildStatItem('Step', '$currentStep/3'),
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
                      // Instructions
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Prepare Fruit Salad',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentStep <= 3 
                                    ? 'Step $currentStep: Tap the knife to uncover a fruit'
                                    : 'Fruit salad ready! All fruits uncovered!',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Fruits and knife grid
                      Expanded(
                        child: _buildFruitsGrid(isSmallScreen: true),
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
                // Top bar with title
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
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
                              'Fruit Salad - Level 2',
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
                                _buildCompactStatItem('Step', '$currentStep/3'),
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
                              'Fruit Salad - Level 2',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                _buildTimer(),
                                const SizedBox(width: 16),
                                _buildStatItem('Score', score.toString()),
                                const SizedBox(width: 16),
                                _buildStatItem('Step', '$currentStep/3'),
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
                      // Left side - Instructions
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Prepare Fruit Salad',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                currentStep <= 3 
                                      ? 'Step $currentStep: Tap the knife to uncover a fruit'
                                      : 'Fruit salad ready! All fruits uncovered!',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Icon(
                                Icons.restaurant_menu,
                                size: 80,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Right side - Fruits and knife grid
                      Expanded(
                        flex: 2,
                        child: _buildFruitsGrid(isSmallScreen: false),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildFruitsGrid({required bool isSmallScreen}) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isSmallScreen ? 2 : 3, // Back to original layout
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.7, // Even larger images
        ),
        itemCount: currentDisplayFruits.length,
        itemBuilder: (context, index) {
          final fruit = currentDisplayFruits[index];
          
          if (fruit.isKnife) {
            // Knife item - make it tappable with continuous animation
            return ScaleTransition(
              scale: _continuousKnifeScaleAnimation,
              child: GestureDetector(
                onTap: _handleKnifeTap,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.orange,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      fruit.assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          } else {
            // Fruit item - show full image without box
            String assetPath = fruit.assetPath;
            if (fruit.isUncovered) {
              // Change to uncovered image
              if (fruit.name.contains('Mango')) {
                assetPath = 'assets/Uncovered Mango.jpeg';
              } else if (fruit.name.contains('Papaya') || fruit.name.contains('Papaw')) {
                assetPath = 'assets/Uncovered Papaw.jpeg';
              } else if (fruit.name.contains('Banana')) {
                assetPath = 'assets/Uncovered Banana.jpeg';
              }
            }
            
            return ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 40, color: Colors.grey),
                  );
                },
              ),
            );
          }
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
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

class FruitLevel2 {
  final String name;
  final String assetPath;
  bool isUncovered;
  final bool isKnife;

  FruitLevel2({
    required this.name,
    required this.assetPath,
    this.isUncovered = false,
    this.isKnife = false,
  });
}
