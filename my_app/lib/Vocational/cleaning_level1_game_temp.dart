import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import '../auth_service.dart';
import '../services/student_data_service.dart';

class CleaningLevel1Game extends StatelessWidget {
  const CleaningLevel1Game({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cleaning Categorization Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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

    return const CleaningGameScreen();
  }
}

class CleaningGameScreen extends StatefulWidget {
  const CleaningGameScreen({Key? key}) : super(key: key);

  @override
  State<CleaningGameScreen> createState() => _CleaningGameScreenState();
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

class _CleaningGameScreenState extends State<CleaningGameScreen> with TickerProviderStateMixin {
  // Game variables
  late List<CleaningItem> allItems;
  late List<CleaningItem> availableItems;
  late List<CleaningItem> droppedItems;
  String? draggedItem;
  String currentCategory = 'Cleaning Tools';
  int score = 0;
  int attempts = 1; // Default attempt count is 1
  int levelScoreLimit = 30; // 3 steps * 10 points each
  bool isGameComplete = false;
  int currentStep = 0;
  List<String> categories = ['Cleaning Tools', 'Waste', 'Recycling'];
  String currentMessage = 'Step 1: Drag cleaning tools to the drop area';
  bool gameStarted = false;
  bool isUnderstood = false;
  
  // Timer variables
  int _seconds = 0;
  Timer? _timer;
  
  // Animation controllers
  late AnimationController _dropAnimationController;
  late Animation<double> _dropAnimation;
  late AnimationController _popController;
  
  // Confetti controller
  late ConfettiController _confettiController;
  
  // Animation state
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    
    // Initialize confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    
    // Initialize drop animation
    _dropAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _dropAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _dropAnimationController, curve: Curves.easeInOut),
    );
    
    _popController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _startTimer();
    
    _animationsInitialized = true;
  }
  
  void _initializeGame() {
    // All cleaning items
    allItems = [
      // Cleaning Tools
      CleaningItem(name: 'Broom', assetPath: 'assets/Broom.jpeg', category: 'Cleaning Tools'),
      CleaningItem(name: 'Mop', assetPath: 'assets/Mob.jpeg', category: 'Cleaning Tools'),
      CleaningItem(name: 'Bucket', assetPath: 'assets/Bucket.png', category: 'Cleaning Tools'),
      CleaningItem(name: 'Sponge', assetPath: 'assets/Sponge.png', category: 'Cleaning Tools'),
      
      // Waste
      CleaningItem(name: 'Trash Bag', assetPath: 'assets/Trash_Bag.png', category: 'Waste'),
      CleaningItem(name: 'Food Waste', assetPath: 'assets/Food_Waste.png', category: 'Waste'),
      CleaningItem(name: 'Paper Waste', assetPath: 'assets/Paper_Waste.png', category: 'Waste'),
      CleaningItem(name: 'Plastic Waste', assetPath: 'assets/Plastic_Waste.png', category: 'Waste'),
      
      // Recycling
      CleaningItem(name: 'Glass Bottle', assetPath: 'assets/Glass_Bottle.png', category: 'Recycling'),
      CleaningItem(name: 'Aluminum Can', assetPath: 'assets/Aluminum_Can.png', category: 'Recycling'),
      CleaningItem(name: 'Cardboard', assetPath: 'assets/Cardboard.png', category: 'Recycling'),
      CleaningItem(name: 'Newspaper', assetPath: 'assets/Newspaper.png', category: 'Recycling'),
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
      // Wrong item - show feedback and increment attempts
      setState(() {
        attempts++; // Increment attempt count for wrong answer
        currentMessage = 'Not a ${currentCategory.toLowerCase()}! Try again!';
      });
      
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          currentMessage = 'Step ${currentStep + 1}: Drag ${currentCategory.toLowerCase()} to the drop area';
        });
      });
    }
  }
  
  Future<void> _saveGameResults() async {
    try {
      final authService = AuthService();
      final studentId = authService.currentStudentId;
      if (studentId == null) {
        print('No student ID available - skipping save');
        return;
      }
      
      print('DEBUG: Saving cleaning level 1 results for student: $studentId');
      
      // Save activity time for tracking
      final completionTime = _seconds;
      final percentage = ((score / (categories.length * 10)) * 100).round();
      
      Map<String, dynamic> activityData = {
        'studentId': studentId,
        'moduleName': 'Cleaning',
        'startTime': DateTime.now().subtract(Duration(seconds: completionTime)).toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'completionPercentage': percentage.roundToDouble(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      final firestore = FirebaseFirestore.instance;
      final activityDoc = await firestore.collection('activities').add(activityData);
      print('DEBUG: Cleaning activity time saved successfully');
      
      // Store individual level data using new service with activityId
      await StudentDataService.storeLevelData(
        studentId: studentId,
        level: 1,
        score: score,
        attempts: attempts,
        timeSpent: _seconds,
        difficultyLevel: 'Easy',
        activityId: activityDoc.id, // Foreign key to activities collection
      );
      
      print('DEBUG: Cleaning Level 1 data stored successfully');

    } catch (e) {
      print('DEBUG: Error saving cleaning game results: $e');
    }
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
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
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
              const SizedBox(height: 5),
              const Text(
                'Difficulty Level 01',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final actualScore = score > 30 ? 30 : score; // Cap score at maximum 30
                  final statsText = 'Time: ${_formatTime(_seconds)}\nScore: $actualScore/30\nAttempts: $attempts';
                  return Text(
                    statsText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                '(10 marks for each correct step)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Navigate to cleaning level 2 when it's created
                  // For now, just go back to game menu
                  Navigator.of(context).pushReplacementNamed('/game_menu');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
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
                    color: Color(0xFF2196F3),
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
                        'Step: ${currentStep + 1}/${categories.length}',
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
                    ],
                  ),
                ),
                
                // Message display
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUnderstood ? Colors.green : Color(0xFF2196F3),
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
                        animation: _popController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: isUnderstood ? _popController.value : 1.0,
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
                              currentMessage = 'Great! Now start dragging ${currentCategory.toLowerCase()} to the drop area';
                              gameStarted = true;
                            });
                            
                            // Pop out animation
                            _popController.forward().then((_) {
                              _popController.reverse();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF2196F3),
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
                                        color: candidateData.isNotEmpty ? Colors.green : Color(0xFF2196F3),
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
                                          Icons.cleaning_services,
                                          size: 60,
                                          color: Color(0xFF2196F3),
                                        ),
                                        const SizedBox(height: 15),
                                        Text(
                                          'Drop ${currentCategory} Here',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2196F3),
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
                                                  border: Border.all(color: Color(0xFF2196F3), width: 2),
                                                  color: Colors.white,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.asset(
                                                    item.assetPath,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Icon(
                                                        Icons.cleaning_services,
                                                        size: 30,
                                                        color: Color(0xFF2196F3),
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
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(10),
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
                                                  Expanded(
                                                    child: Image.asset(
                                                      item.assetPath,
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Icon(
                                                          Icons.cleaning_services,
                                                          size: 30,
                                                          color: Color(0xFF2196F3),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item.name,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF2196F3),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            childWhenDragging: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withOpacity(0.5),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: AnimatedBuilder(
                                              animation: _dropAnimation,
                                              builder: (context, child) {
                                                return Transform.scale(
                                                  scale: isDraggable ? _dropAnimation.value : 1.0,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: isDraggable ? Colors.white : Colors.grey.withOpacity(0.7),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(
                                                        color: isDraggable ? Color(0xFF2196F3) : Colors.grey,
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
                                                                Icons.cleaning_services,
                                                                size: 30,
                                                                color: isDraggable ? Color(0xFF2196F3) : Colors.grey,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          item.name,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: isDraggable ? Color(0xFF2196F3) : Colors.grey,
                                                          ),
                                                          textAlign: TextAlign.center,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
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
                    : Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 60,
                                color: Color(0xFF2196F3),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Get Ready!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Click "Understood" to start the game',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2196F3),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
          
          // Confetti
          Positioned.fill(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF2196F3),
                Colors.green,
                Colors.orange,
                Colors.pink,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
