import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'retail_level2_game.dart';
import '../auth_service.dart';

class RetailLevel1Game extends StatelessWidget {
  const RetailLevel1Game({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retail Categorization Game',
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
  late List<RetailItem> availableItems;
  late List<RetailItem> droppedItems;
  String? draggedItem;
  String currentCategory = 'Snacks';
  int score = 0;
  int attempts = 0;
  int levelScoreLimit = 30; // 3 steps * 10 points each
  bool isGameComplete = false;
  int currentStep = 0;
  List<String> categories = ['Snacks', 'Dairy', 'Drinks'];
  String currentMessage = 'Step 1: Drag snacks to the drop area';
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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _dropAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _dropAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _popController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _popAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _popController,
      curve: Curves.elasticInOut,
    ));
    
    _animationsInitialized = true;
  }
  
  void _initializeGame() {
    // All retail items - only using specified items
    allItems = [
      // Energy Drinks
      RetailItem(name: 'Energy Drink', assetPath: 'assets/Energy_Drink.png', category: 'Drinks'),
      
      // Snacks
      RetailItem(name: 'Garlic Chips', assetPath: 'assets/Garlic_Chips.png', category: 'Snacks'),
      RetailItem(name: 'Onion Chips', assetPath: 'assets/Onion_chips.png', category: 'Snacks'),
      RetailItem(name: 'Potato Chips', assetPath: 'assets/Potato_chips.png', category: 'Snacks'),
      RetailItem(name: 'Chocolate', assetPath: 'assets/Chocolate.png', category: 'Snacks'),
      
      // Dairy
      RetailItem(name: 'Milk Bottle', assetPath: 'assets/Milk_bottle.png', category: 'Dairy'),
      RetailItem(name: 'Cheese', assetPath: 'assets/Cheese.png', category: 'Dairy'),
      RetailItem(name: 'Butter', assetPath: 'assets/Butter.png', category: 'Dairy'),
      
      // Drinks
      RetailItem(name: 'Coke', assetPath: 'assets/Coke.png', category: 'Drinks'),
      RetailItem(name: 'Soda', assetPath: 'assets/Soda_Bottle.png', category: 'Drinks'),
    ];
    
    _setupCurrentStep();
  }
  
  void _setupCurrentStep() {
    // Get items for current category
    final categoryItems = allItems.where((item) => item.category == currentCategory).toList();
    final random = math.Random();
    categoryItems.shuffle(random);
    
    // Select 4 items to drag (2 from current category, 2 from other categories)
    final currentCategoryItems = categoryItems.take(2).toList();
    final otherCategoryItems = allItems
        .where((item) => item.category != currentCategory)
        .toList()..shuffle(random);
    final mixedItems = otherCategoryItems.take(2).toList();
    
    availableItems = [...currentCategoryItems, ...mixedItems];
    availableItems.shuffle(random);
    droppedItems = [];
    
    setState(() {
      currentMessage = 'Step ${currentStep + 1}: Drag ${currentCategory.toLowerCase()} to the drop area';
    });
  }
  
  void _handleItemDrop(String itemName) {
    final item = availableItems.firstWhere((item) => item.name == itemName);
    
    if (item.category == currentCategory) {
      setState(() {
        droppedItems.add(item);
        availableItems.removeWhere((i) => i.name == itemName);
        score += 10;
        
        // Animate drop
        _dropAnimationController.forward().then((_) {
          _dropAnimationController.reverse();
        });
        
        // Trigger confetti
        _confettiController.play();
        
        // Check if step is complete
        if (droppedItems.length >= 2) {
          Future.delayed(const Duration(seconds: 2), () {
            if (currentStep < categories.length - 1) {
              currentStep++;
              currentCategory = categories[currentStep];
              _setupCurrentStep();
            } else {
              isGameComplete = true;
              _saveGameResults();
              _showLevelCompleteDialog();
            }
          });
        }
      });
    } else {
      // Wrong item - show feedback
      setState(() {
        currentMessage = 'Not a ${currentCategory.toLowerCase()}! Try again!';
      });
      
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          currentMessage = 'Step ${currentStep + 1}: Drag ${currentCategory.toLowerCase()} to the drop area';
        });
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

  Future<void> _saveGameResults() async {
    try {
      if (Firebase.apps.isEmpty) {
        print('DEBUG: Firebase not initialized - skipping retail game results save');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final authService = AuthService();
      final studentId = authService.currentStudentId;
      if (studentId == null) {
        print('No student ID available - skipping save');
        return;
      }
      
      print('DEBUG: Saving retail game results for student: $studentId');
      
      // Calculate game statistics
      final maxScore = categories.length * 10; // 10 points per category
      final percentage = (score / maxScore) * 100;
      final completionTime = _seconds;
      
      print('DEBUG: Retail game stats - Score: $score/$maxScore, Percentage: $percentage%, Time: $completionTime seconds');
      
      // Save module progress
      Map<String, dynamic> moduleProgress = {
        'studentId': studentId,
        'moduleKey': 'retail_level_01',
        'moduleName': 'Retail Level 1',
        'completionPercentage': percentage.roundToDouble(),
        'totalTimeSpent': completionTime,
        'lastAccessed': DateTime.now().toIso8601String(),
        'isCompleted': percentage >= 100,
        'startedAt': DateTime.now().subtract(Duration(seconds: completionTime)).toIso8601String(),
        'completedAt': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      await firestore.collection('module_progress').add(moduleProgress);
      print('DEBUG: Retail module progress saved successfully - Completion: ${percentage.roundToDouble()}%');

      // Save activity time
      Map<String, dynamic> activityTime = {
        'studentId': studentId,
        'activityType': 'retail_game',
        'startTime': DateTime.now().subtract(Duration(seconds: completionTime)).toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'duration': completionTime,
        'completionPercentage': percentage.roundToDouble(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      await firestore.collection('activities').add(activityTime);
      print('DEBUG: Retail activity time saved successfully');

    } catch (e) {
      print('DEBUG: Error saving retail game results: $e');
    }
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
    
    if (_animationsInitialized) {
      _dropAnimationController.dispose();
      _popController.dispose();
    }
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
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
              colors: [Color(0xFFFF6B35), Color(0xFFE53E3E)],
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
                Icons.emoji_events,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 15),
              const Text(
                'Level 1 Complete!',
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFFFF6B35),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force landscape orientation at build time
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    return WillPopScope(
      onWillPop: () async {
        // Always allow back navigation to go to previous screen
        return true;
      },
      child: Scaffold(
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
                        'Time: ${_formatTime(_seconds)}',
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
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUnderstood ? Colors.green : Color(0xFFFF6B35),
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
                              currentMessage = 'Great! Now start dragging ${currentCategory.toLowerCase()} to drop area';
                              gameStarted = true;
                            });
                            
                            // Start timer when game begins
                            _startTimer();
                            
                            // Pop out animation
                            _popController.forward().then((_) {
                              _popController.reverse();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFFFF6B35),
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
                
                // Game area - Left Drop Area + Right Drag Area
                Expanded(
                  child: gameStarted
                    ? Row(
                        children: [
                          // Left side - Drop area
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              child: DragTarget<String>(
                                onAccept: (data) {
                                  _handleItemDrop(data!);
                                },
                                builder: (context, candidateData, rejectedData) {
                                  return Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: candidateData.isNotEmpty ? Colors.green : Color(0xFFFF6B35),
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
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shopping_basket,
                                          size: 60,
                                          color: Color(0xFFFF6B35),
                                        ),
                                        const SizedBox(height: 15),
                                        Text(
                                          'Drop ${currentCategory} Here',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFF6B35),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '${droppedItems.length}/2 items',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        // Show dropped items
                                        if (droppedItems.isNotEmpty)
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            children: droppedItems.map((item) {
                                              return Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Color(0xFFFF6B35), width: 2),
                                                  color: Colors.white,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.asset(
                                                    item.assetPath,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Icon(
                                                        Icons.shopping_cart,
                                                        size: 30,
                                                        color: Color(0xFFFF6B35),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          // Right side - Drag area
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: const EdgeInsets.all(10),
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
                                  if (availableItems.isNotEmpty)
                                    Expanded(
                                      child: GridView.builder(
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 1.8,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                        ),
                                        itemCount: availableItems.length,
                                        itemBuilder: (context, index) {
                                          final item = availableItems[index];
                                          final isDraggable = item.category == currentCategory;
                                          
                                          return Draggable<String>(
                                            data: item.name,
                                            feedback: Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(15),
                                                border: Border.all(color: Color(0xFFFF6B35), width: 2),
                                                color: Colors.white,
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(13),
                                                child: Image.asset(
                                                  item.assetPath,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.image,
                                                      size: 40,
                                                      color: Color(0xFFFF6B35),
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
                                                border: Border.all(
                                                  color: isDraggable ? Color(0xFFFF6B35) : Colors.grey,
                                                  width: isDraggable ? 3 : 2,
                                                ),
                                                color: Colors.white,
                                                boxShadow: isDraggable ? [
                                                  BoxShadow(
                                                    color: Color(0xFFFF6B35).withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ] : null,
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Image.asset(
                                                      item.assetPath,
                                                      fit: BoxFit.contain,
                                                      color: isDraggable ? null : Colors.grey.withOpacity(0.5),
                                                      colorBlendMode: isDraggable ? null : BlendMode.saturation,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Icon(
                                                          isDraggable ? Icons.shopping_cart : Icons.lock,
                                                          size: 30,
                                                          color: isDraggable ? Color(0xFFFF6B35) : Colors.grey,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    item.name,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: isDraggable ? Color(0xFFFF6B35) : Colors.grey,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
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
          if (droppedItems.isNotEmpty)
            Positioned.fill(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Color(0xFFFF6B35),
                  Color(0xFFE53E3E),
                  Color(0xFFC53030),
                  Color(0xFFFFD700),
                ],
              ),
            ),
          
          // Level complete dialog
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
                          'Level 1 Complete!',
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
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => RetailLevel2Game(initialTime: _seconds),
                              ),
                            );
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
                            'Start Level 2',
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
      ),
    );
  }
}
