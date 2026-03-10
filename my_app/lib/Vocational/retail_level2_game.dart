import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';

class RetailLevel2Game extends StatelessWidget {
  const RetailLevel2Game({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retail Categorization Game Level 2',
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

    return const RetailGameScreen();
  }
}

class RetailGameScreen extends StatefulWidget {
  const RetailGameScreen({Key? key}) : super(key: key);

  @override
  State<RetailGameScreen> createState() => _RetailGameScreenState();
}

class RetailItem {
  final String name;
  final String assetPath;
  final String category;

  RetailItem({
    required this.name,
    required this.assetPath,
    required this.category,
  });
}

class _RetailGameScreenState extends State<RetailGameScreen> with TickerProviderStateMixin {
  // Game variables
  late List<RetailItem> allItems;
  late RetailItem targetItem;
  late List<RetailItem> options;
  int score = 0;
  int attempts = 0;
  int levelScoreLimit = 100;
  bool isAnswered = false;
  String? selectedItemName;
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
  
  // Game step tracking
  int currentStep = 0;
  List<String> categories = ['Fruits', 'Dairy', 'Snacks', 'Drinks'];
  String currentCategory = 'Fruits';
  bool gameStarted = false;
  bool isUnderstood = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    
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
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.elasticInOut,
    ));
    
    _questionAnimationController.repeat(reverse: true);
    _startTimer();
  }
  
  void _initializeGame() {
    // All retail items
    allItems = [
      // Fruits
      RetailItem(name: 'Orange', assetPath: 'assets/Orange.png', category: 'Fruits'),
      RetailItem(name: 'Pineapple', assetPath: 'assets/Pine apple.png', category: 'Fruits'),
      RetailItem(name: 'Banana', assetPath: 'assets/banana.png', category: 'Fruits'),
      RetailItem(name: 'Apple', assetPath: 'assets/kitchen1.jpg', category: 'Fruits'),
      RetailItem(name: 'Grapes', assetPath: 'assets/kitchen1.jpg', category: 'Fruits'),
      
      // Dairy
      RetailItem(name: 'Butter', assetPath: 'assets/Butter.png', category: 'Dairy'),
      RetailItem(name: 'Cheese', assetPath: 'assets/Cheese.png', category: 'Dairy'),
      RetailItem(name: 'Milk Bottle', assetPath: 'assets/Milk.png', category: 'Dairy'),
      RetailItem(name: 'Yogurt', assetPath: 'assets/kitchen1.jpg', category: 'Dairy'),
      RetailItem(name: 'Ice Cream', assetPath: 'assets/kitchen1.jpg', category: 'Dairy'),
      
      // Snacks
      RetailItem(name: 'Chocolate', assetPath: 'assets/Chocolate.png', category: 'Snacks'),
      RetailItem(name: 'Onion Chips', assetPath: 'assets/Onion chips.png', category: 'Snacks'),
      RetailItem(name: 'Garlic Chips', assetPath: 'assets/Garlic chips.png', category: 'Snacks'),
      RetailItem(name: 'Cookies', assetPath: 'assets/kitchen1.jpg', category: 'Snacks'),
      RetailItem(name: 'Popcorn', assetPath: 'assets/kitchen1.jpg', category: 'Snacks'),
      
      // Drinks
      RetailItem(name: 'Energy Drink', assetPath: 'assets/Energy drink.png', category: 'Drinks'),
      RetailItem(name: 'Soda Bottle', assetPath: 'assets/Soda bottle.png', category: 'Drinks'),
      RetailItem(name: 'Coke Bottle', assetPath: 'assets/Coke bottle.png', category: 'Drinks'),
      RetailItem(name: 'Juice Box', assetPath: 'assets/kitchen1.jpg', category: 'Drinks'),
      RetailItem(name: 'Water Bottle', assetPath: 'assets/kitchen1.jpg', category: 'Drinks'),
    ];
    
    _setupNewQuestion();
  }
  
  void _setupNewQuestion() {
    // Get items for current category
    final categoryItems = allItems.where((item) => item.category == currentCategory).toList();
    
    if (categoryItems.isEmpty) return;
    
    // Select random target item from current category
    final random = math.Random();
    targetItem = categoryItems[random.nextInt(categoryItems.length)];
    
    // Get wrong options (items from other categories)
    final wrongOptions = allItems.where((item) => item.category != currentCategory).toList();
    wrongOptions.shuffle(random);
    
    // Select 3 wrong options (harder than level 1)
    final selectedWrong = wrongOptions.take(3).toList();
    
    // Combine target with wrong options and shuffle
    options = [targetItem, ...selectedWrong];
    options.shuffle(random);
    
    setState(() {
      isAnswered = false;
      selectedItemName = null;
      isCorrect = false;
    });
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
    // Reset to portrait orientation when exiting game
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _scaleController.dispose();
    _questionAnimationController.dispose();
    _dialogAnimationController.dispose();
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _handleItemSelection(RetailItem selectedItem) {
    if (isAnswered) return;
    
    setState(() {
      isAnswered = true;
      selectedItemName = selectedItem.name;
      isCorrect = (selectedItem.category == currentCategory);
      attempts++;
      
      if (isCorrect) {
        score += 10;
        _confettiController.play();
        _scaleController.forward().then((_) {
          _scaleController.reverse();
        });
        
        // Check if level is complete
        if (score >= levelScoreLimit) {
          Future.delayed(const Duration(seconds: 2), () {
            _dialogAnimationController.forward();
          });
        } else {
          // Move to next step or category
          Future.delayed(const Duration(seconds: 2), () {
            if (currentStep < categories.length - 1) {
              currentStep++;
              currentCategory = categories[currentStep];
              _setupNewQuestion();
            } else {
              // All categories complete
              _dialogAnimationController.forward();
            }
          });
        }
      } else {
        // Wrong answer - show feedback and setup new question
        Future.delayed(const Duration(seconds: 2), () {
          _setupNewQuestion();
        });
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
                
                // Guidance message
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
                          'Step ${currentStep + 1}: Select ${currentCategory}',
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
                    ? Column(
                        children: [
                          // Question area
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Color(0xFFFF6B35), width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: AnimatedBuilder(
                              animation: _questionScaleAnimation,
                              builder: (context, child) => Transform.scale(
                                scale: _questionScaleAnimation.value,
                                child: Column(
                                  children: [
                                    Text(
                                      'Select ${currentCategory}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF6B35),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'from options below',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Options grid (4 options for level 2)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 40),
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4, // 4 options instead of 3
                                  childAspectRatio: 1.8, // Make images shorter
                                  crossAxisSpacing: 15,
                                  mainAxisSpacing: 15,
                                ),
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final item = options[index];
                                  final isSelected = selectedItemName == item.name;
                                  final showResult = isAnswered;
                                  final isCorrectAnswer = isCorrect && item.name == selectedItemName;
                                  final isWrongAnswer = !isCorrect && item.name == selectedItemName;
                                  
                                  return GestureDetector(
                                    onTap: () => _handleItemSelection(item),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: showResult
                                              ? (isCorrectAnswer ? Color(0xFFFF6B35) : Colors.red)
                                              : Color(0xFFFF6B35),
                                          width: showResult ? 3 : 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Image.asset(
                                              item.assetPath,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.shopping_cart,
                                                  size: 40,
                                                  color: Color(0xFFFF6B35),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            item.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFFF6B35),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          if (showResult)
                                            Icon(
                                              isCorrectAnswer ? Icons.check_circle : Icons.cancel,
                                              color: isCorrectAnswer ? Color(0xFFFF6B35) : Colors.red,
                                              size: 24,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(),
                ),
              ],
            ),
          ),
          
          // Confetti overlay
          if (isCorrect)
            Positioned.fill(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.02,
                numberOfParticles: 30,
                gravity: 0.25,
                colors: [
                  Color(0xFFFF6B35),
                  Color(0xFFE53E3E),
                  Color(0xFFC53030),
                  Color(0xFFFFD700),
                ],
              ),
            ),
          
          // Level complete dialog
          if (score >= levelScoreLimit || (currentStep >= categories.length - 1 && isAnswered))
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _dialogScaleAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _dialogScaleAnimation.value,
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
                              'Level 2 Complete!',
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
                                backgroundColor: Color(0xFFFF6B35),
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
              ),
            ),
        ],
      ),
    );
  }
}
