import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:confetti/confetti.dart';
import '../game_menu_new.dart';

class CleaningLevel1Game extends StatefulWidget {
  const CleaningLevel1Game({super.key});

  @override
  State<CleaningLevel1Game> createState() => _CleaningLevel1GameState();
}

class CleaningItem {
  final String name;
  final String assetPath;
  final String category;

  CleaningItem({
    required this.name,
    required this.assetPath,
    required this.category,
  });
}

class _CleaningLevel1GameState extends State<CleaningLevel1Game> with TickerProviderStateMixin {
  // Game variables
  List<CleaningItem> availableItems = [];
  List<CleaningItem> droppedItems = [];
  String? draggedItem;
  bool isGameComplete = false;
  int score = 0;
  int attempts = 0;
  int _seconds = 0;
  Timer? _timer;
  
  // Confetti controller
  late ConfettiController _confettiController;
  
  // Animation controller
  late AnimationController _dropAnimationController;
  late Animation<double> _dropScaleAnimation;
  
  // Pop animation for drop box
  late AnimationController _popController;
  late Animation<double> _popAnimation;
  
  // Game step tracking
  int currentStep = 0;
  int totalSteps = 3; // 3 steps: Broom, Mob, Cloth
  String currentMessage = 'Step 1: Drag the correct item to the drop area';
  bool gameStarted = false;
  bool isUnderstood = false;
  
  // Target item for each step
  CleaningItem? targetItem;
  
  // Animation state
  bool _animationsInitialized = false;
  
  // All cleaning items
  List<CleaningItem> allCleaningItems = [
    CleaningItem(name: 'Broom', assetPath: 'assets/Broom.jpeg', category: 'Tools'),
    CleaningItem(name: 'Mob', assetPath: 'assets/Mob.jpeg', category: 'Tools'),
    CleaningItem(name: 'Cloth', assetPath: 'assets/cloth.jpeg', category: 'Supplies'),
  ];
  
  // Force landscape orientation
  _CleaningLevel1GameState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void initState() {
    super.initState();
    
    // Force landscape orientation at build time
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Initialize confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    
    // Initialize drop animation
    _dropAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _dropScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _dropAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // Initialize pop animation for drop box
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
    
    // Initialize game
    _initializeGame();
    
    print('Cleaning Level 1 initialized');
    
    // Start timer
    _startTimer();
  }
  
  void _initializeGame() {
    currentStep = 0;
    droppedItems = [];
    isGameComplete = false;
    gameStarted = false;
    isUnderstood = false;
    
    // Generate first step
    _generateNewStep();
  }
  
  void _generateNewStep() {
    if (currentStep >= totalSteps) {
      _showGameCompleteDialog();
      return;
    }
    
    // Set target item for this step
    targetItem = allCleaningItems[currentStep];
    
    // Create 4 answer options (including the correct answer)
    List<CleaningItem> answerOptions = [];
    answerOptions.add(targetItem!); // Add correct answer
    
    // Add 3 random other items (can include duplicates if needed)
    List<CleaningItem> otherItems = allCleaningItems.where((item) => item.name != targetItem!.name).toList();
    for (int i = 0; i < 3 && i < otherItems.length; i++) {
      answerOptions.add(otherItems[i]);
    }
    
    // If we need more items (less than 4 total), add some duplicates
    while (answerOptions.length < 4) {
      answerOptions.add(otherItems[currentStep % otherItems.length]);
    }
    
    // Shuffle the answer options
    answerOptions.shuffle();
    availableItems = answerOptions;
    
    currentMessage = 'Step ${currentStep + 1}: Drag the ${targetItem!.name} to the drop area';
  }
  
  void _showGameCompleteDialog() {
    _timer?.cancel();
    setState(() {
      isGameComplete = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
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
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.emoji_events,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Level Complete!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Time: $_seconds seconds\nScore: $score',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => GameMenuNew(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Back to Game Menu',
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
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    // Reset to portrait orientation when exiting the game
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    if (_animationsInitialized) {
      _dropAnimationController.dispose();
      _popController.dispose();
    }
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startPopAnimation() {
    if (_animationsInitialized) {
      _popController.repeat(reverse: true);
    }
  }

  void _stopPopAnimation() {
    if (_animationsInitialized) {
      _popController.stop();
      _popController.reset();
    }
  }

  void _handleItemDrop(String itemName) {
    if (!gameStarted || isUnderstood) return;
    
    // Find the dropped item
    CleaningItem? droppedItem;
    for (var item in availableItems) {
      if (item.name == itemName) {
        droppedItem = item;
        break;
      }
    }
    
    if (droppedItem == null) return;
    
    setState(() {
      attempts++;
      droppedItems.add(droppedItem!);
      
      // Check if the dropped item is the correct target item
      if (droppedItem!.name == targetItem!.name) {
        score += 10;
        _dropAnimationController.forward().then((_) {
          _dropAnimationController.reverse();
        });
        _confettiController.play();
        
        // Move to next step after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              currentStep++;
              droppedItems = [];
              _confettiController.stop();
              _generateNewStep();
            });
          }
        });
      } else {
        // Wrong category - remove the item and add it back
        droppedItems.remove(droppedItem!);
        availableItems.add(droppedItem!);
      }
    });
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
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Score and Time Header
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B35), // Orange color like retail games
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
                        'Time: $_seconds',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Step: ${currentStep + 1}/$totalSteps',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Guidance message
                if (!gameStarted || isUnderstood)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(0xFFFF6B35), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          currentMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B35),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (!gameStarted) ...[
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                gameStarted = true;
                                isUnderstood = false;
                                currentMessage = 'Step ${currentStep + 1}: Drag the ${targetItem!.name} to the drop area';
                              });
                              _startPopAnimation();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF6B35),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Understood'),
                          ),
                        ],
                      ],
                    ),
                  ),
                
                // Game area
                Expanded(
                  child: Row(
                    children: [
                      // Left side - Drop area
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Drop box
                              AnimatedBuilder(
                                animation: _popAnimation,
                                builder: (context, child) => Transform.scale(
                                  scale: gameStarted && !isUnderstood ? _popAnimation.value : 1.0,
                                  child: Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Color(0xFFFF6B35),
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: DragTarget<String>(
                                      onAccept: (itemName) {
                                        _handleItemDrop(itemName);
                                      },
                                      builder: (context, candidateData, rejectedData) {
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // Target item display
                                            if (targetItem != null) ...[
                                              Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: Color(0xFFFF6B35),
                                                    width: 2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Image.asset(
                                                  targetItem!.assetPath,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.cleaning_services,
                                                      size: 40,
                                                      color: Color(0xFFFF6B35),
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                targetItem!.name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFFF6B35),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                            Text(
                                              'Drop here',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Right side - Drag area
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Available items (2x2 format)
                              if (gameStarted && !isUnderstood)
                                GridView.builder(
                                  shrinkWrap: true,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 1.5,
                                    crossAxisSpacing: 15,
                                    mainAxisSpacing: 15,
                                  ),
                                  itemCount: availableItems.length,
                                  itemBuilder: (context, index) {
                                    final item = availableItems[index];
                                    
                                    return Draggable<String>(
                                      data: item.name,
                                      feedback: Container(
                                        width: 100,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFFF6B35).withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Color(0xFFFF6B35), width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              item.assetPath,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.cleaning_services,
                                                  size: 40,
                                                  color: Colors.white,
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      childWhenDragging: Container(
                                        width: 100,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade400, width: 2),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.help_outline,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Color(0xFFFF6B35),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              item.assetPath,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.cleaning_services,
                                                  size: 40,
                                                  color: Color(0xFFFF6B35),
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFFF6B35),
                                              ),
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
                ),
              ],
            ),
          ),
          
          // Game completion dialog
          if (isGameComplete)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                        const Icon(
                          Icons.emoji_events,
                          size: 60,
                          color: Color(0xFFFF6B35),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Level Complete!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Time: $_seconds seconds\nScore: $score',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Continue',
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
              ),
            ),
        ],
      ),
    );
  }
}
