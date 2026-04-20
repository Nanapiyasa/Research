import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'game_menu_new.dart';
import 'boiling_screen.dart';

class TeaLevel3Game extends StatefulWidget {
  final int initialTime;
  
  const TeaLevel3Game({Key? key, this.initialTime = 0}) : super(key: key);

  @override
  _TeaLevel3GameState createState() => _TeaLevel3GameState();
}

class _TeaLevel3GameState extends State<TeaLevel3Game> with TickerProviderStateMixin {
  // Force landscape immediately
  _TeaLevel3GameState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  
  // Game variables
  List<TeaIngredient> availableIngredients = [];
  List<String> droppedIngredients = [];
  String? draggedIngredient;
  bool isGameComplete = false;
  int score = 0;
  int _seconds = 0;
  Timer? _timer;
  
  // Confetti controller
  late ConfettiController _confettiController;
  
  // Animation controller
  late AnimationController _kettleAnimationController;
  late Animation<double> _kettleScaleAnimation;
  
  // Pop animation for stove
  late AnimationController _popController;
  late Animation<double> _popAnimation;
  
  // Pop animation for button
  late AnimationController _buttonPopController = AnimationController(
    duration: const Duration(milliseconds: 1500),
    vsync: this,
  );
  late Animation<double> _buttonPopAnimation = Tween<double>(
    begin: 1.0,
    end: 1.15,
  ).animate(CurvedAnimation(
    parent: _buttonPopController,
    curve: Curves.elasticInOut,
  ));
  
  // Stove state
  String currentStoveImage = 'assets/kitchen1.jpg'; // Will be replaced with flaming stove
  
  // Game step tracking
  int currentStep = 0;
  List<String> correctOrder = ['Kettle']; // Only 1 step for level 3
  String currentMessage = 'Step 1: Drag the kettle to the flaming stove to heat water';
  bool gameStarted = false;
  bool isUnderstood = false;
  
  // Animation state
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _kettleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _kettleScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _kettleAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _popController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _popAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _popController,
      curve: Curves.elasticOut,
    ));
    
    // Mark animations as initialized
    _animationsInitialized = true;
    
    // Initialize game
    _initializeGame();
    
    print('Tea Level 3 initialized');
  }

  void _initializeGame() {
    availableIngredients = [
      TeaIngredient(name: 'Kettle', assetPath: 'assets/Empty_Kettle.png'),
    ];
    
    // Don't shuffle for single ingredient
    droppedIngredients = [];
    currentStoveImage = 'assets/flames.png';
    isGameComplete = false;
    score = 0;
    _seconds = widget.initialTime;
    currentStep = 0;
    
    // Start continuous button animation
    _startButtonAnimation();
    
    print('Tea Level 3 game initialized with ${availableIngredients.length} ingredients');
  }
  
  void _startButtonAnimation() {
    if (!gameStarted) {
      _buttonPopController.repeat(reverse: true);
    }
  }
  
  void _stopButtonAnimation() {
    _buttonPopController.stop();
    _buttonPopController.reset();
  }
  
  Widget _buildStoveContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Flaming Stove',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              currentStoveImage,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 70,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'Drop kettle here',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        if (droppedIngredients.isNotEmpty)
          ...droppedIngredients.map((ingredient) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ingredient,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )),
      ],
    );
  }
  
  bool _isIngredientDropped(String ingredientName) {
    return droppedIngredients.contains(ingredientName);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startPopAnimation() {
    _popController.forward().then((_) {
      _popController.reverse();
    });
  }

  void _handleDrop(String data) {
    if (data == 'Kettle' && !droppedIngredients.contains('Kettle')) {
      setState(() {
        droppedIngredients.add('Kettle');
        currentStep++;
        score += 10;
        currentMessage = 'Kettle placed on stove! Moving to heating screen...';
      });
      
      // Start pop animation
      _startPopAnimation();
      
      // Navigate to boiling screen after a short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const BoilingScreen(),
            ),
          );
        }
      });
    } else {
      currentMessage = 'Try again! Drag the kettle to the flaming stove.';
    }
  }

  void _resetGame() {
    setState(() {
      availableIngredients.shuffle();
      droppedIngredients = [];
      currentStoveImage = 'assets/flames.png';
      isGameComplete = false;
      score = 0;
      
      print('Initialized ${availableIngredients.length} ingredients');
    });
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
              colors: [Colors.orange.shade400, Colors.orange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 15),
              const Text(
                'Level 3 Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Time: ${_formatTime(_seconds)}\nScore: $score',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to game menu since this is the last tea level
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const GameMenuNew(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Complete',
                  style: TextStyle(
                    fontSize: 16,
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
    // Keep landscape orientation when navigating to next level
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _confettiController.dispose();
    _kettleAnimationController.dispose();
    _popController.dispose();
    _buttonPopController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force landscape orientation at build time
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Add a small delay to ensure orientation is applied
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
    
    return WillPopScope(
      onWillPop: () async {
        // Always allow back navigation to go to previous screen
        return true;
      },
      child: Scaffold(
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
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Score and Time Header
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B35), // Orange color
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Score: $score',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Time: ${_formatTime(_seconds)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Step: ${currentStep + 1}/1',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Message area
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    currentMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Game area using Tea Level 1 template
                Expanded(
                  child: Row(
                    children: [
                      // Left side - Flaming Stove (drop zone)
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          child: DragTarget<String>(
                            onAccept: (data) => _handleDrop(data),
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: candidateData.isNotEmpty ? Colors.green : Colors.grey,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: _animationsInitialized 
                                  ? ScaleTransition(
                                      scale: _kettleScaleAnimation,
                                      child: _buildStoveContent(),
                                    )
                                  : _buildStoveContent(),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Right side - Kettle (draggable)
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: [
                              const Text(
                                'Available Items',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 15),
                              if (availableIngredients.isNotEmpty)
                                Expanded(
                                  child: GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.8,
                                      crossAxisSpacing: 15,
                                      mainAxisSpacing: 15,
                                    ),
                                    itemCount: availableIngredients.length,
                                    itemBuilder: (context, index) {
                                      final ingredient = availableIngredients[index];
                                      final isDraggable = !_isIngredientDropped(ingredient.name);
                                      
                                      if (isDraggable) {
                                        return Draggable<String>(
                                          data: ingredient.name,
                                          feedback: Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(15),
                                              border: Border.all(color: Colors.orange, width: 2),
                                              color: Colors.white,
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(13),
                                              child: Image.asset(
                                                ingredient.assetPath,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.kitchen, size: 30, color: Colors.grey),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          childWhenDragging: Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(15),
                                              border: Border.all(color: Colors.grey, width: 2),
                                              color: Colors.grey[300],
                                            ),
                                            child: const Icon(Icons.kitchen, size: 30, color: Colors.grey),
                                          ),
                                          child: Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(15),
                                              border: Border.all(color: Colors.orange, width: 2),
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(13),
                                              child: Image.asset(
                                                ingredient.assetPath,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.kitchen, size: 30, color: Colors.grey),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        // Empty slot for dropped ingredient
                                        return Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(color: Colors.grey.shade400, width: 1),
                                            color: Colors.grey.shade200,
                                          ),
                                          child: const Icon(Icons.check, color: Colors.green, size: 30),
                                        );
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
              ],
            ),
          ),
          
          // Dark overlay covering complete background when game hasn't started
          if (!gameStarted)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                ),
              ),
            ),
          
          // Start Heating button - Front layer overlay
          if (!gameStarted)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                    animation: _buttonPopAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonPopAnimation.value,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              gameStarted = true;
                              isUnderstood = false;
                              currentMessage = 'Step 1: Drag the kettle to the flaming stove to heat water';
                            });
                            
                            // Stop button animation when pressed
                            _stopButtonAnimation();
                            
                            // Start timer when game begins
                            _startTimer();
                            
                            _startPopAnimation();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0BF449),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.3),
                          ),
                          child: const Text(
                            'Start Heating',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ),
            ),
          
          // Confetti overlay
          if (isGameComplete)
            Positioned.fill(
              child: Align(
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
            ),
        ],
      ),
      ),
    );
  }
}

class TeaIngredient {
  final String name;
  final String assetPath;

  TeaIngredient({required this.name, required this.assetPath});
}
