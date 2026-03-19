import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';

class CleaningLevel1FruitGame extends StatelessWidget {
  const CleaningLevel1FruitGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cleaning Fruit Matching Game Level 1',
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

    return const CleaningFruitGameScreen();
  }
}

class FruitItem {
  final String name;
  final String assetPath;
  final String category;

  FruitItem({
    required this.name,
    required this.assetPath,
    required this.category,
  });
}

class CleaningFruitGameScreen extends StatefulWidget {
  const CleaningFruitGameScreen({Key? key}) : super(key: key);

  @override
  State<CleaningFruitGameScreen> createState() => _CleaningFruitGameScreenState();
}

class _CleaningFruitGameScreenState extends State<CleaningFruitGameScreen> with TickerProviderStateMixin {
  // Game variables
  late List<FruitItem> allItems;
  late List<FruitItem> availableItems;
  late List<FruitItem> droppedItems;
  String? draggedItem;
  String currentCategory = 'Citrus';
  int score = 0;
  int attempts = 0;
  int levelScoreLimit = 30; // 3 steps * 10 points each
  bool isGameComplete = false;
  int currentStep = 0;
  List<String> categories = ['Citrus', 'Berries', 'Tropical', 'Stone'];
  String currentMessage = 'Step 1: Drag citrus fruits to the cleaning area';
  bool gameStarted = false;
  bool isUnderstood = false;
  
  // Timer variables
  int _seconds = 0;
  Timer? _timer;
  
  // Animation controllers
  late AnimationController _dropAnimationController;
  late Animation<double> _dropAnimation;
  late AnimationController _popController;
  late Animation<double> _popAnimation;
  
  // Confetti controller
  late ConfettiController _confettiController;
  
  // Animation state
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    // Initialize animation controllers
    _dropAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _dropAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
  }
  
  void _initializeGame() {
    // All fruit items with categories
    allItems = [
      // Citrus fruits
      FruitItem(name: 'Orange', assetPath: 'assets/Orange.png', category: 'Citrus'),
      FruitItem(name: 'Lemon', assetPath: 'assets/Lemon.png', category: 'Citrus'),
      FruitItem(name: 'Lime', assetPath: 'assets/Lime.png', category: 'Citrus'),
      FruitItem(name: 'Grapefruit', assetPath: 'assets/Grapefruit.png', category: 'Citrus'),
      
      // Berries
      FruitItem(name: 'Strawberry', assetPath: 'assets/Strawberry.png', category: 'Berries'),
      FruitItem(name: 'Blueberry', assetPath: 'assets/Blueberry.png', category: 'Berries'),
      FruitItem(name: 'Raspberry', assetPath: 'assets/Raspberry.png', category: 'Berries'),
      FruitItem(name: 'Cranberry', assetPath: 'assets/Cranberry.png', category: 'Berries'),
      
      // Tropical fruits
      FruitItem(name: 'Pineapple', assetPath: 'assets/Pine_Apple.png', category: 'Tropical'),
      FruitItem(name: 'Mango', assetPath: 'assets/Mango.png', category: 'Tropical'),
      FruitItem(name: 'Papaya', assetPath: 'assets/Papaya.png', category: 'Tropical'),
      FruitItem(name: 'Coconut', assetPath: 'assets/Coconut.png', category: 'Tropical'),
      
      // Stone fruits
      FruitItem(name: 'Apple', assetPath: 'assets/apple.png', category: 'Stone'),
      FruitItem(name: 'Peach', assetPath: 'assets/Peach.png', category: 'Stone'),
      FruitItem(name: 'Plum', assetPath: 'assets/Plum.png', category: 'Stone'),
      FruitItem(name: 'Cherry', assetPath: 'assets/Cherry.png', category: 'Stone'),
    ];
    
    _generateNewStep();
  }
  
  void _generateNewStep() {
    if (currentStep >= categories.length) {
      _showGameCompleteDialog();
      return;
    }
    
    currentCategory = categories[currentStep];
    availableItems = allItems.where((item) => item.category == currentCategory).toList();
    droppedItems.clear();
    currentMessage = 'Step ${currentStep + 1}: Drag ${currentCategory.toLowerCase()} fruits to the cleaning area';
    attempts = 0;
  }
  
  void _handleItemDrop(String itemName) {
    if (draggedItem != null) {
      final item = availableItems.firstWhere((item) => item.name == draggedItem);
      if (!droppedItems.contains(item)) {
        setState(() {
          droppedItems.add(item);
          attempts++;
          score += 10;
        });
        
        // Trigger drop animation
        _dropAnimationController.forward().then((_) {
          _dropAnimationController.reset();
        });
        
        // Check if step is complete
        if (droppedItems.length == availableItems.length) {
          _confettiController.play();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _showStepCompleteDialog();
            }
          });
        }
      }
    }
    setState(() {
      draggedItem = null;
    });
  }
  
  void _startPopAnimation() {
    _popController.forward().then((_) {
      _popController.reverse();
    });
  }
  
  void _showStepCompleteDialog() {
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
                  Icons.check_circle,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Step ${currentStep + 1} Complete!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Great job cleaning the ${currentCategory.toLowerCase()} fruits!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    currentStep++;
                    _generateNewStep();
                  });
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
    );
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
                'Fruit Cleaning Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Excellent work organizing all fruits!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
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
                  Column(
                    children: [
                      Text(
                        'Steps',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${currentStep + 1}/${categories.length}',
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
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
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
                  'Back to Menu',
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
    _timer?.cancel();
    _dropAnimationController.dispose();
    _popController.dispose();
    _confettiController.dispose();
    super.dispose();
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
                    color: Color(0xFFFF6B35), // Orange color like retail Level 1
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
                        'Step: ${currentStep + 1}/4',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Message display
                if (!gameStarted || isUnderstood)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
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
                                currentMessage = 'Step ${currentStep + 1}: Drag ${currentCategory.toLowerCase()} fruits to the cleaning area';
                              });
                              _startTimer();
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
                                    // Drop box
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
                                                  Icon(
                                                    Icons.cleaning_services,
                                                    size: 60,
                                                    color: Color(0xFFFF6B35),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    currentCategory,
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFFF6B35),
                                                    ),
                                                  ),
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
                                        'Cleaned Items:',
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
                                                fontSize: 12,
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
                                    // Available items (1x3 format)
                                    GridView.builder(
                                      shrinkWrap: true,
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        childAspectRatio: 1.2,
                                        crossAxisSpacing: 15,
                                        mainAxisSpacing: 15,
                                      ),
                                      itemCount: availableItems.length,
                                      itemBuilder: (context, index) {
                                        final item = availableItems[index];
                                        return Draggable<String>(
                                          data: item.name,
                                          feedback: Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Color(0xFFFF6B35).withOpacity(0.8),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Color(0xFFFF6B35),
                                                width: 2,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          childWhenDragging: Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.5),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Container(
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
                                                Expanded(
                                                  child: Image.asset(
                                                    item.assetPath,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Icon(
                                                        Icons.apple,
                                                        size: 30,
                                                        color: Color(0xFFFF6B35),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFFF6B35),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
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
