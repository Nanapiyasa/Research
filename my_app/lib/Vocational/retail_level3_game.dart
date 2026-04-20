import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import '../auth_service.dart';
import '../firebase_config.dart';
import '../services/student_data_service.dart';
import 'game_menu_new.dart';

class RetailLevel3Game extends StatelessWidget {
  final int initialTime;
  
  const RetailLevel3Game({Key? key, this.initialTime = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retail Customer Service Game Level 3',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: LandscapeGame(initialTime: initialTime),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LandscapeGame extends StatelessWidget {
  final int initialTime;
  
  const LandscapeGame({Key? key, required this.initialTime}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return RetailCustomerGameScreen(initialTime: initialTime);
  }
}

class RetailItem {
  final String name;
  final String assetPath;
  final String category;
  final double price;

  RetailItem({
    required this.name,
    required this.assetPath,
    required this.category,
    required this.price,
  });
}

class RetailCustomerGameScreen extends StatefulWidget {
  final int initialTime;
  
  const RetailCustomerGameScreen({Key? key, this.initialTime = 0}) : super(key: key);

  @override
  State<RetailCustomerGameScreen> createState() => _RetailCustomerGameScreenState();
}

class _RetailCustomerGameScreenState extends State<RetailCustomerGameScreen> with TickerProviderStateMixin {
  // Game variables
  late List<RetailItem> allItems;
  late List<RetailItem> shelf1Items;
  late List<RetailItem> shelf2Items;
  late List<String> availableCategories;
  late String currentCustomerRequest;
  RetailItem? targetItem;
  int score = 0;
  int currentStep = 1;
  int totalSteps = 10;
  bool isGameComplete = false;
  String currentMessage = 'Find the correct item for the customer';
  bool isCorrectSelection = false;
  
  // Timer variables
  int _seconds = 0;
  Timer? _timer;
  
  // Game statistics
  int attempts = 1; // Default attempt count is 1
  
  // Animation controllers
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;
  late AnimationController _popController;
  late Animation<double> _popAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
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
    _scanAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );
    
    _popController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _popAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _popController, curve: Curves.elasticOut),
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    
    _seconds = widget.initialTime;
    // Start scanning animation and timer
    _scanAnimationController.repeat(reverse: true);
    _startTimer();
  }
  
  void _initializeGame() {
    // All retail items with categories
    allItems = [
      // Fruits
      RetailItem(name: 'Apple', assetPath: 'assets/apple.png', category: 'Fruits', price: 1.99),
      RetailItem(name: 'Banana', assetPath: 'assets/Banana.png', category: 'Fruits', price: 0.99),
      RetailItem(name: 'Pine Apple', assetPath: 'assets/Pine_Apple.png', category: 'Fruits', price: 2.99),
      RetailItem(name: 'Grapes', assetPath: 'assets/Grapes.png', category: 'Fruits', price: 3.99),
      
      // Dairy
      RetailItem(name: 'Milk Bottle', assetPath: 'assets/Milk_bottle.png', category: 'Dairy', price: 4.99),
      RetailItem(name: 'Cheese', assetPath: 'assets/Cheese.png', category: 'Dairy', price: 5.99),
      RetailItem(name: 'Butter', assetPath: 'assets/Butter.png', category: 'Dairy', price: 4.49),
      RetailItem(name: 'Yogurt', assetPath: 'assets/Yogurt.png', category: 'Dairy', price: 2.99),
      
      // Snacks
      RetailItem(name: 'Potato Chips', assetPath: 'assets/Potato_chips.png', category: 'Snacks', price: 3.49),
      RetailItem(name: 'Garlic Chips', assetPath: 'assets/Garlic_Chips.png', category: 'Snacks', price: 2.49),
      RetailItem(name: 'Onion Chips', assetPath: 'assets/Onion_chips.png', category: 'Snacks', price: 2.29),
      RetailItem(name: 'Chocolate', assetPath: 'assets/Chocolate.png', category: 'Snacks', price: 2.99),
      
      // Drinks
      RetailItem(name: 'Energy Drink', assetPath: 'assets/Energy_Drink.png', category: 'Drinks', price: 3.99),
      RetailItem(name: 'Coke', assetPath: 'assets/Coke.png', category: 'Drinks', price: 1.99),
      RetailItem(name: 'Soda', assetPath: 'assets/Soda_Bottle.png', category: 'Drinks', price: 2.49),
      RetailItem(name: 'Juice', assetPath: 'assets/Juice.png', category: 'Drinks', price: 3.49),
    ];
    
    availableCategories = ['Fruits', 'Dairy', 'Snacks', 'Drinks'];
    _generateNewStep();
  }
  
  void _generateNewStep() {
    final random = math.Random();
    
    // Select two random categories for this step
    final selectedCategories = <String>[];
    while (selectedCategories.length < 2) {
      final category = availableCategories[random.nextInt(availableCategories.length)];
      if (!selectedCategories.contains(category)) {
        selectedCategories.add(category);
      }
    }
    
    // Get items from selected categories
    final category1Items = allItems.where((item) => item.category == selectedCategories[0]).toList();
    final category2Items = allItems.where((item) => item.category == selectedCategories[1]).toList();
    
    // Shuffle and select items for shelves
    category1Items.shuffle(random);
    category2Items.shuffle(random);
    
    // Place items in shelves (4-6 items per shelf)
    shelf1Items = category1Items.take(random.nextInt(3) + 4).toList();
    shelf2Items = category2Items.take(random.nextInt(3) + 4).toList();
    
    // Select target item from either shelf
    final allShelfItems = [...shelf1Items, ...shelf2Items];
    targetItem = allShelfItems[random.nextInt(allShelfItems.length)];
    
    // Generate customer request
    if (targetItem != null) {
      _generateCustomerRequest();
    }
  }
  
  void _generateCustomerRequest() {
    final requests = [
      "I need ${targetItem!.name}. Can you find it for me?",
      "Where can I find ${targetItem!.name}?",
      "Could you help me get ${targetItem!.name}?",
      "I'm looking for ${targetItem!.name}. Do you have it?",
      "Can you show me where ${targetItem!.name} is?",
      "I want to buy ${targetItem!.name}. Where is it?",
      "Help me find ${targetItem!.name}, please.",
      "Do you have ${targetItem!.name} in stock?",
      "I need ${targetItem!.name} from the shelves.",
      "Can you locate ${targetItem!.name} for me?",
    ];
    
    final random = math.Random();
    currentCustomerRequest = requests[random.nextInt(requests.length)];
  }
  
  void _handleItemTap(RetailItem item) {
    if (targetItem == null || isGameComplete) return;
    
    if (item.name == targetItem!.name) {
      // Correct selection
      setState(() {
        score += 10;
        isCorrectSelection = true;
        currentMessage = 'Correct! You found ${item.name}';
      });
      
      // Trigger animations
      _popController.forward().then((_) {
        _popController.reverse();
      });
      _confettiController.play();
      
      // Move to next step after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          if (currentStep >= totalSteps) {
            _showLevelCompleteDialog();
          } else {
            setState(() {
              currentStep++;
              isCorrectSelection = false;
              currentMessage = 'Great! Next customer request...';
            });
            _generateNewStep();
          }
        }
      });
    } else {
      // Wrong selection - increment attempts
      setState(() {
        attempts++; // Increment attempt count for wrong answer
        currentMessage = 'Wrong item! Try again. Look for ${targetItem!.name}';
      });
      
      // Shake animation
      _shakeController.forward().then((_) {
        _shakeController.reverse();
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
  
  void _stopTimer() {
    _timer?.cancel();
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showFullModuleSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF004E89), Color(0xFF002855)],
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
              // Header
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 40,
                      color: Color(0xFFFF6B35),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      '🏆 RETAIL MODULE COMPLETE 🏆',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Module Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Color(0xFF004E89).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Module Performance Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004E89),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Level Performance
                    _buildLevelSummary('Level 1', 'Categorization', 30, '3 steps completed'),
                    const SizedBox(height: 10),
                    _buildLevelSummary('Level 2', 'Billing', 100, '10 items billed'),
                    const SizedBox(height: 10),
                    _buildLevelSummary('Level 3', 'Shelf Organization', score, '$currentStep/$totalSteps steps'),
                    const SizedBox(height: 15),
                    
                    // Overall Stats
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Color(0xFF004E89).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _buildOverallStat('Total Module Score', '${score + 30 + 100}/230', Color(0xFF004E89)),
                          const SizedBox(height: 10),
                          _buildOverallStat('Total Time Spent', _formatTime(_seconds + widget.initialTime), Colors.grey.shade700),
                          const SizedBox(height: 10),
                          _buildOverallStat('Total Attempts', '${attempts + 1 + 1}', Colors.grey.shade700),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Review Levels'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => GameMenuNew()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Back to Game Menu'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSummary(String level, String skill, int maxScore, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            level,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF004E89),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            skill,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Score: $maxScore points',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF004E89),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStat(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  void _showLevelCompleteDialog() async {
    _stopTimer();
    setState(() {
      isGameComplete = true;
    });
    
    // Save level data to student_data collection
    await _saveLevelData();
    
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
              const Icon(
                Icons.emoji_events,
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
              const SizedBox(height: 5),
              const Text(
                'Difficulty Level 03',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final statsText = 'Time: ${_formatTime(_seconds)}\nScore: $score/100\nAttempts: $attempts';
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
              const SizedBox(height: 10),
              Text(
                'you have successfully completed\nRetail Assistant Module',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Module Summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final totalScore = score; // This level score (10 steps * 10 marks = 100)
                        final totalTime = _seconds + widget.initialTime; // This level time + previous levels time
                        final totalAttempts = attempts; // This level attempts
                        
                        return Column(
                          children: [
                            Text(
                              'Total Marks: $totalScore/100',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Time: ${_formatTime(totalTime)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Attempts: $totalAttempts',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFFFF6B35).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Color(0xFFFF6B35).withOpacity(0.3)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '🏆 RETAIL MODULE COMPLETE 🏆',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF6B35),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'All three levels completed successfully!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Level 1: Categorization (30 points)\n'
                                    'Level 2: Billing (100 points)\n'
                                    'Level 3: Shelf Organization (100 points)',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
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
                        _formatTime(_seconds),
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
                        '$currentStep/$totalSteps',
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
                  _showFullModuleSummary();
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
  
  Future<void> _saveLevelData() async {
    try {
      final authService = AuthService();
      final studentId = authService.currentStudentId;
      if (studentId == null) {
        print('No student ID available - skipping save');
        return;
      }
      
      print('DEBUG: Saving retail level 3 results for student: $studentId');
      
      // Save activity time for tracking
      final completionTime = _seconds;
      final percentage = ((score / (totalSteps * 10)) * 100).round();
      
      Map<String, dynamic> activityData = {
        'studentId': studentId,
        'moduleName': 'Retail',
        'startTime': DateTime.now().subtract(Duration(seconds: completionTime)).toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'completionPercentage': percentage.roundToDouble(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      final firestore = FirebaseFirestore.instance;
      final activityDoc = await firestore.collection('activities').add(activityData);
      print('DEBUG: Retail Level 3 activity time saved successfully');
      
      // Store individual level data using new service with activityId
      await StudentDataService.storeLevelData(
        studentId: studentId,
        level: 3,
        score: score,
        attempts: attempts,
        timeSpent: _seconds,
        difficultyLevel: 'Hard',
        activityId: activityDoc.id, // Foreign key to activities collection
      );
      
      print('DEBUG: Retail Level 3 data stored successfully');
    } catch (e) {
      print('Error saving retail level 3 results: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save game results: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scanAnimationController.dispose();
    _popController.dispose();
    _shakeController.dispose();
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
                    color: Color(0xFFFF6B35),
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
                        'Step: $currentStep/$totalSteps',
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
                
                // Game Area
                Expanded(
                  child: Column(
                    children: [
                      // Customer Request Area
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Color(0xFFFF6B35), size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                currentCustomerRequest,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF6B35),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Shelves Area
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              // Shelf 1
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
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
                                    children: [
                                      Text(
                                        '${shelf1Items.first.category} Shelf',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFF6B35),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: GridView.builder(
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            childAspectRatio: 1.2,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                          ),
                                          itemCount: shelf1Items.length,
                                          itemBuilder: (context, index) {
                                            final item = shelf1Items[index];
                                            return GestureDetector(
                                              onTap: () => _handleItemTap(item),
                                              child: AnimatedBuilder(
                                                animation: isCorrectSelection && item.name == targetItem?.name 
                                                    ? _popAnimation 
                                                    : _shakeAnimation,
                                                builder: (context, child) {
                                                  return Transform.scale(
                                                    scale: isCorrectSelection && item.name == targetItem?.name 
                                                        ? _popAnimation.value 
                                                        : 1.0,
                                                    child: Transform.translate(
                                                      offset: Offset(
                                                        isCorrectSelection && item.name == targetItem?.name 
                                                            ? 0 
                                                            : _shakeAnimation.value * math.sin(_shakeController.value * math.pi * 2),
                                                        0,
                                                      ),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(10),
                                                          border: Border.all(
                                                            color: isCorrectSelection && item.name == targetItem?.name 
                                                                ? Colors.green 
                                                                : Color(0xFFFF6B35),
                                                            width: 2,
                                                          ),
                                                          color: isCorrectSelection && item.name == targetItem?.name 
                                                              ? Colors.green.shade50 
                                                              : Colors.white,
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
                                                                    Icons.shopping_cart,
                                                                    size: 30,
                                                                    color: Color(0xFFFF6B35),
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
                                                                color: isCorrectSelection && item.name == targetItem?.name 
                                                                    ? Colors.green 
                                                                    : Color(0xFFFF6B35),
                                                              ),
                                                              textAlign: TextAlign.center,
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ],
                                                        ),
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
                              
                              // Shelf 2
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
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
                                    children: [
                                      Text(
                                        '${shelf2Items.first.category} Shelf',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFF6B35),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: GridView.builder(
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            childAspectRatio: 1.2,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                          ),
                                          itemCount: shelf2Items.length,
                                          itemBuilder: (context, index) {
                                            final item = shelf2Items[index];
                                            return GestureDetector(
                                              onTap: () => _handleItemTap(item),
                                              child: AnimatedBuilder(
                                                animation: isCorrectSelection && item.name == targetItem?.name 
                                                    ? _popAnimation 
                                                    : _shakeAnimation,
                                                builder: (context, child) {
                                                  return Transform.scale(
                                                    scale: isCorrectSelection && item.name == targetItem?.name 
                                                        ? _popAnimation.value 
                                                        : 1.0,
                                                    child: Transform.translate(
                                                      offset: Offset(
                                                        isCorrectSelection && item.name == targetItem?.name 
                                                            ? 0 
                                                            : _shakeAnimation.value * math.sin(_shakeController.value * math.pi * 2),
                                                        0,
                                                      ),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(10),
                                                          border: Border.all(
                                                            color: isCorrectSelection && item.name == targetItem?.name 
                                                                ? Colors.green 
                                                                : Color(0xFFFF6B35),
                                                            width: 2,
                                                          ),
                                                          color: isCorrectSelection && item.name == targetItem?.name 
                                                              ? Colors.green.shade50 
                                                              : Colors.white,
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
                                                                    Icons.shopping_cart,
                                                                    size: 30,
                                                                    color: Color(0xFFFF6B35),
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
                                                                color: isCorrectSelection && item.name == targetItem?.name 
                                                                    ? Colors.green 
                                                                    : Color(0xFFFF6B35),
                                                              ),
                                                              textAlign: TextAlign.center,
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ],
                                                        ),
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
