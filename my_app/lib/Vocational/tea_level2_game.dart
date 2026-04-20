import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'boiling_screen.dart';

class TeaLevel2Game extends StatefulWidget {
  final int initialTime;
  
  const TeaLevel2Game({Key? key, this.initialTime = 0}) : super(key: key);

  @override
  _TeaLevel2GameState createState() => _TeaLevel2GameState();
}

class _TeaLevel2GameState extends State<TeaLevel2Game> with TickerProviderStateMixin {
  // Force landscape immediately
  _TeaLevel2GameState() {
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
  
  // Pop animation for tap
  late AnimationController _popController;
  late Animation<double> _popAnimation;
  
  // Tap state
  String currentTapImage = 'assets/kitchen1.jpg'; // Will be replaced with tap image
  
  // Game step tracking
  int currentStep = 0;
  List<String> correctOrder = ['Kettle']; // Only 1 step for level 2
  String currentMessage = 'Step 1: Drag the kettle to the tap to fill water';
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
    
    // Initialize confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    
    // Initialize kettle animation
    _kettleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _kettleScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _kettleAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // Initialize pop animation for tap
    _popController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _popAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _popController,
      curve: Curves.elasticInOut,
    ));
    
    // Mark animations as initialized
    _animationsInitialized = true;
    
    // Simple ingredient initialization
    availableIngredients = [
      TeaIngredient(name: 'Kettle', assetPath: 'assets/Empty_Kettle.png'),
    ];
    
    print('DEBUG: Loading kettle from assets/Empty_Kettle.png');
    
    // Don't shuffle for single ingredient
    droppedIngredients = [];
    currentTapImage = 'assets/Tap.png';
    isGameComplete = false;
    score = 0;
    
    print('Tea Level 2 initialized with ${availableIngredients.length} ingredients');
    
    _seconds = widget.initialTime;
    // Start timer
    _startTimer();
  }
  
  void _startPopAnimation() {
    if (currentStep == 0) { // Only animate for kettle step
      _popController.repeat(reverse: true);
    }
  }
  
  void _stopPopAnimation() {
    _popController.stop();
    _popController.reset();
  }
  
  String _getCurrentRequiredIngredient() {
    if (currentStep < correctOrder.length) {
      return correctOrder[currentStep];
    }
    return '';
  }
  
  bool _isIngredientDraggable(String ingredientName) {
    return ingredientName == _getCurrentRequiredIngredient();
  }
  
  void _handleIngredientDrop(String ingredientName) {
    print('Dropped ingredient: $ingredientName');
    
    // Check if this is the correct ingredient for current step
    if (ingredientName == _getCurrentRequiredIngredient()) {
      setState(() {
        droppedIngredients.add(ingredientName);
        availableIngredients.removeWhere((ingredient) => ingredient.name == ingredientName);
        score += 10;
        
        // Update tap image based on step
        if (currentStep == 0) {
          currentTapImage = 'assets/kitchen1.jpg'; // Will be replaced with filled kettle image
          currentMessage = 'Great! Kettle is filled with water!';
          _stopPopAnimation(); // Stop pop animation after kettle dropped
        }
        
        // Animate tap
        _kettleAnimationController.forward().then((_) {
          _kettleAnimationController.reverse();
        });
        
        // Trigger confetti
        _confettiController.play();
        
        // Move to next step
        currentStep++;
        
        // Check if game is complete
        if (currentStep >= correctOrder.length) {
          isGameComplete = true;
          currentMessage = 'Water Filling Complete! Well done!';
          _showLevelCompleteDialog();
        }
      });
    } else {
      // Wrong ingredient - show message
      setState(() {
        currentMessage = 'Not yet! Please add ${_getCurrentRequiredIngredient()} first';
      });
    }
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
                Icons.local_cafe,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 15),
              const Text(
                'Level 2 Complete!',
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
                  // Navigate to power button screen after water filling
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => BoilingScreen(initialTime: _seconds),
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
                  'Next Step',
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
    // Keep landscape orientation when navigating to power button screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    if (_animationsInitialized) {
      _kettleAnimationController.dispose();
      _popController.dispose();
    }
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  
  Widget _buildTapContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Water Tap',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        if (currentStep == 0)
          // Pop animation for kettle step
          AnimatedBuilder(
            animation: _popAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _popAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      currentTapImage,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.water_drop, size: 30, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          )
        else
          // Normal tap display for other steps
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                currentTapImage,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.water_drop, size: 30, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 15),
        Text(
          'Drop ${_getCurrentRequiredIngredient()} here',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Force landscape orientation at build time
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
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
          
          // Game content
          SafeArea(
            child: Column(
              children: [
                // Score and Time Header
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Water Filling',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Score: $score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Time: ${_formatTime(_seconds)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Message display
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUnderstood ? Colors.green : Colors.blue,
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
                    children: [
                      AnimatedBuilder(
                        animation: _popAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: isUnderstood ? _popAnimation.value : 1.0,
                            child: const Icon(
                              Icons.info,
                              color: Colors.white,
                              size: 20,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          currentMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!gameStarted && !isUnderstood)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isUnderstood = true;
                              currentMessage = 'Great! Now drag the kettle to the tap to fill water';
                              gameStarted = true;
                            });
                            
                            // Pop out animation
                            _popController.forward().then((_) {
                              _popController.reverse();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Understood',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Game area
                Expanded(
                  child: Row(
                    children: [
                      // Left side - Tap (drop zone)
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          child: DragTarget<String>(
                            onAccept: (data) {
                              _handleIngredientDrop(data);
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: candidateData.isNotEmpty ? Colors.blue : Colors.grey,
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
                                      child: _buildTapContent(),
                                    )
                                  : _buildTapContent(),
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
                                      mainAxisSpacing: 15,
                                      crossAxisSpacing: 15,
                                      childAspectRatio: 1.0,
                                    ),
                                    itemCount: availableIngredients.length,
                                    itemBuilder: (context, index) {
                                      final ingredient = availableIngredients[index];
                                      final isDraggable = _isIngredientDraggable(ingredient.name);
                                      print('Building ingredient: ${ingredient.name}, Draggable: $isDraggable');
                                      
                                      if (isDraggable) {
                                        return Draggable<String>(
                                          data: ingredient.name,
                                          feedback: Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(15),
                                              border: Border.all(color: Colors.blue, width: 2),
                                              color: Colors.white,
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(13),
                                              child: Image.asset(
                                                ingredient.assetPath,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  print('Error loading ${ingredient.assetPath}: $error');
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.water_drop, size: 30, color: Colors.grey),
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
                                              border: Border.all(color: Colors.grey, width: 1),
                                              color: Colors.grey[300],
                                            ),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(15),
                                              border: Border.all(color: Colors.green, width: 3), // Green border for draggable
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.green.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(13),
                                              child: Image.asset(
                                                ingredient.assetPath,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  print('Error loading ${ingredient.assetPath}: $error');
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.water_drop, size: 30, color: Colors.grey),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        // Locked ingredient
                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(color: Colors.grey, width: 2),
                                            color: Colors.grey.withOpacity(0.5),
                                          ),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(13),
                                                child: Image.asset(
                                                  ingredient.assetPath,
                                                  fit: BoxFit.contain,
                                                  color: Colors.grey.withOpacity(0.5),
                                                  colorBlendMode: BlendMode.saturation,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[200],
                                                      child: const Icon(Icons.lock, size: 30, color: Colors.grey),
                                                    );
                                                  },
                                                ),
                                              ),
                                              const Center(
                                                child: Icon(
                                                  Icons.lock,
                                                  size: 24,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
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
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.purple,
                Colors.pink,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TeaIngredient {
  final String name;
  final String assetPath;
  
  TeaIngredient({
    required this.name,
    required this.assetPath,
  });
}
