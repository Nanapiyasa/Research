import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:confetti/confetti.dart';
import '../game_menu_new.dart';

class FruitSaladLevel4Game extends StatelessWidget {
  const FruitSaladLevel4Game({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fruit Salad Level 4 Game',
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

    return const FruitSaladGameScreen();
  }
}

class FruitSaladItem {
  final String name;
  final String assetPath;
  final String category;

  FruitSaladItem({
    required this.name,
    required this.assetPath,
    required this.category,
  });
}

class FruitSaladGameScreen extends StatefulWidget {
  const FruitSaladGameScreen({Key? key}) : super(key: key);

  @override
  State<FruitSaladGameScreen> createState() => _FruitSaladGameScreenState();
}

class _FruitSaladGameScreenState extends State<FruitSaladGameScreen> with TickerProviderStateMixin {
  // Game variables
  List<FruitSaladItem> availableItems = [];
  List<FruitSaladItem> droppedItems = [];
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
  int totalSteps = 4; // 4 steps for fruit salad making
  String currentMessage = 'Step 1: Drag sugar to the fruit salad';
  bool gameStarted = false;
  bool isUnderstood = false;
  
  // Target item for each step
  FruitSaladItem? targetItem;
  
  // Animation state
  bool _animationsInitialized = false;
  
  // All fruit salad items
  List<FruitSaladItem> allSaladItems = [
    FruitSaladItem(name: 'Sugar', assetPath: 'assets/Sugar.png', category: 'Ingredient'),
    FruitSaladItem(name: 'Mango', assetPath: 'assets/Mango_Slice.png', category: 'Fruit'),
    FruitSaladItem(name: 'Apple', assetPath: 'assets/apple.png', category: 'Fruit'),
    FruitSaladItem(name: 'Banana', assetPath: 'assets/Banana.png', category: 'Fruit'),
    FruitSaladItem(name: 'Orange', assetPath: 'assets/Orange.png', category: 'Fruit'),
    FruitSaladItem(name: 'Grapes', assetPath: 'assets/Grapes.png', category: 'Fruit'),
  ];
  
  // Force landscape orientation
  _FruitSaladGameScreenState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void initState() {
    super.initState();
    _initializeGame();
    
    print('Fruit Salad Level 4 initialized');
    
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    // Initialize animation controllers
    _dropAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _dropScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dropAnimationController, curve: Curves.easeInOut),
    );
    
    _popController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _popAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _popController, curve: Curves.elasticOut),
    );
    
    setState(() {
      _animationsInitialized = true;
    });
    
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
    if (currentStep == 0) {
      targetItem = allSaladItems[0]; // Sugar
      currentMessage = 'Step 1: Drag sugar to the fruit salad';
    } else {
      targetItem = allSaladItems[1]; // Mango
      currentMessage = 'Step ${currentStep + 1}: Add ${targetItem!.name} to the fruit salad';
    }
    
    // Create 4 answer options (including the correct answer)
    List<FruitSaladItem> answerOptions = [];
    answerOptions.add(targetItem!); // Add correct answer
    
    // Add 3 random other items
    List<FruitSaladItem> otherItems = allSaladItems.where((item) => item.name != targetItem!.name).toList();
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

  void _handleItemDrop(String itemName) {
    if (!gameStarted || isUnderstood) return;
    
    // Find the dropped item
    FruitSaladItem? droppedItem;
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
        // Wrong item - remove from dropped items and continue
        droppedItems.remove(droppedItem!);
        // Could add shake animation or error feedback here
      }
    });
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
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'You have successfully completed\nfruit salad making lesson',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Score',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Time',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${_seconds}s',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to chef menu
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
                  'Back to Chef Menu',
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
  Widget build(BuildContext context) {
    // Force landscape orientation at build time
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    return Scaffold(
      body: Stack(
        children: [
          // Background
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
                  child: gameStarted && !isUnderstood
                      ? Row(
                          children: [
                            // Left side - Drop area
                            Expanded(
                              flex: 1,
                              child: Container(
                                margin: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Fruit salad drop area
                                    AnimatedBuilder(
                                      animation: _popAnimation,
                                      builder: (context, child) => Transform.scale(
                                        scale: _popAnimation.value,
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
                                                  // Cup with mango slice display
                                                  if (currentStep > 0) ...[
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
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Image.asset(
                                                            'assets/Cup.png',
                                                            width: 40,
                                                            height: 40,
                                                            fit: BoxFit.contain,
                                                          ),
                                                          const SizedBox(height: 5),
                                                          Image.asset(
                                                            'assets/Mango_Slice.png',
                                                            width: 30,
                                                            height: 30,
                                                            fit: BoxFit.contain,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ] else ...[
                                                    // Sugar bowl for step 1
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
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            Icons.restaurant,
                                                            size: 40,
                                                            color: Color(0xFFFF6B35),
                                                          ),
                                                          const SizedBox(height: 5),
                                                          Text(
                                                            'Fruit Salad',
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                              color: Color(0xFFFF6B35),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 10),
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
                                    
                                    // Dropped items display
                                    if (droppedItems.isNotEmpty) ...[
                                      const SizedBox(height: 20),
                                      Text(
                                        'Added Ingredients:',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFF6B35),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: droppedItems.map((item) {
                                          return Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Color(0xFFFF6B35),
                                                width: 2,
                                              ),
                                            ),
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFFF6B35),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
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
                                                      Icons.restaurant,
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
                                                      Icons.restaurant,
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
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
