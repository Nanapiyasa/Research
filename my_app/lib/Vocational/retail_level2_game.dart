import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'retail_level3_game.dart';

class RetailLevel2Game extends StatelessWidget {
  const RetailLevel2Game({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retail Billing Game Level 2',
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

    return const RetailBillingGameScreen();
  }
}

class RetailItem {
  final String name;
  final String assetPath;
  final double price;

  RetailItem({
    required this.name,
    required this.assetPath,
    required this.price,
  });
}

class RetailBillingGameScreen extends StatefulWidget {
  const RetailBillingGameScreen({Key? key}) : super(key: key);

  @override
  State<RetailBillingGameScreen> createState() => _RetailBillingGameScreenState();
}

class _RetailBillingGameScreenState extends State<RetailBillingGameScreen> with TickerProviderStateMixin {
  // Game variables
  late List<RetailItem> allItems;
  late List<RetailItem> availableItems;
  late List<RetailItem> scannedItems;
  RetailItem? currentItemForVerification;
  String? draggedItem;
  int score = 0;
  int totalBilledItems = 0;
  int targetBilledItems = 10; // Bill all 10 items
  bool isGameComplete = false;
  String currentMessage = 'Drag items to barcode scanner, then tap to verify billing';
  bool gameStarted = false;
  bool isUnderstood = false;
  bool isWaitingForVerification = false;
  
  // Timer variables
  int _seconds = 0;
  Timer? _timer;
  
  // Animation controllers
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;
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
    _scanAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scanAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.elasticInOut,
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
    _startTimer();
  }
  
  void _initializeGame() {
    // All retail items with prices for billing
    allItems = [
      RetailItem(name: 'Energy Drink', assetPath: 'assets/Energy_Drink.png', price: 3.99),
      RetailItem(name: 'Garlic Chips', assetPath: 'assets/Garlic_Chips.png', price: 2.49),
      RetailItem(name: 'Milk Bottle', assetPath: 'assets/Milk_bottle.png', price: 4.99),
      RetailItem(name: 'Onion Chips', assetPath: 'assets/Onion_chips.png', price: 2.29),
      RetailItem(name: 'Potato Chips', assetPath: 'assets/Potato_chips.png', price: 3.49),
      RetailItem(name: 'Chocolate', assetPath: 'assets/Chocolate.png', price: 2.99),
      RetailItem(name: 'Cheese', assetPath: 'assets/Cheese.png', price: 5.99),
      RetailItem(name: 'Butter', assetPath: 'assets/Butter.png', price: 4.49),
      RetailItem(name: 'Coke', assetPath: 'assets/Coke.png', price: 1.99),
      RetailItem(name: 'Soda', assetPath: 'assets/Soda_Bottle.png', price: 2.49),
    ];
    
    // Shuffle items for random presentation
    final random = math.Random();
    availableItems = List.from(allItems)..shuffle(random);
    scannedItems = [];
    currentItemForVerification = null;
    isWaitingForVerification = false;
  }
  
  void _handleItemDrop(String itemName) {
    if (isWaitingForVerification) {
      setState(() {
        currentMessage = 'Please verify the current item first!';
      });
      return;
    }
    
    final item = availableItems.firstWhere((item) => item.name == itemName);
    
    setState(() {
      currentItemForVerification = item;
      availableItems.removeWhere((i) => i.name == itemName);
      isWaitingForVerification = true;
      currentMessage = 'Tap on the item to verify billing details';
      
      // Animate scan
      _scanAnimationController.forward().then((_) {
        _scanAnimationController.reverse();
      });
    });
  }
  
  void _handleItemTap(RetailItem item) {
    if (currentItemForVerification?.name != item.name) {
      return; // Only allow tapping the current item for verification
    }
    
    // Show item details for billing verification
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
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
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFFF6B35), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    item.assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.shopping_cart,
                        size: 40,
                        color: Color(0xFFFF6B35),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '\$${item.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _completeVerification(item);
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
                  'Verify Billing',
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
  
  void _completeVerification(RetailItem item) {
    setState(() {
      scannedItems.add(item);
      totalBilledItems++;
      score += 10; // Add points for successful verification
      currentItemForVerification = null;
      isWaitingForVerification = false;
      
      // Trigger confetti for successful verification
      _confettiController.play();
      
      // Check if game is complete
      if (totalBilledItems >= targetBilledItems) {
        isGameComplete = true;
        _showLevelCompleteDialog();
      } else {
        currentMessage = 'Billing verified! Drag next item to scanner (${targetBilledItems - totalBilledItems} remaining)';
      }
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
    
    if (_animationsInitialized) {
      _scanAnimationController.dispose();
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
                'Level 2 Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Time: $_seconds seconds\nItems Billed: $totalBilledItems/$targetBilledItems',
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RetailCustomerGameScreen(),
                    ),
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
                  'Start Level 3',
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
                        'Time: $_seconds',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Billed: $totalBilledItems/$targetBilledItems',
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
                              currentMessage = 'Great! Drag an item to scanner, then tap the yellow item to verify';
                              gameStarted = true;
                            });
                            
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
                
                // Game area - Left Barcode Scanner Area + Right Drag Area
                Expanded(
                  child: gameStarted
                    ? Row(
                        children: [
                          // Left side - Barcode Scanner area
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              child: DragTarget<String>(
                                onAccept: (data) {
                                  _handleItemDrop(data!);
                                },
                                onWillAccept: (data) {
                                  return !isWaitingForVerification; // Only accept if not waiting for verification
                                },
                                builder: (context, candidateData, rejectedData) {
                                  return Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: candidateData.isNotEmpty && !isWaitingForVerification 
                                            ? Colors.green 
                                            : isWaitingForVerification 
                                                ? Colors.red 
                                                : Color(0xFFFF6B35),
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
                                    child: Stack(
                                      children: [
                                        // Background content - only show when no item is dropped
                                        if (currentItemForVerification == null)
                                          Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                AnimatedBuilder(
                                                  animation: _scanAnimation,
                                                  builder: (context, child) {
                                                    return Transform.scale(
                                                      scale: _scanAnimation.value,
                                                      child: Icon(
                                                        Icons.qr_code_scanner,
                                                        size: 60,
                                                        color: isWaitingForVerification ? Colors.red : Color(0xFFFF6B35),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 15),
                                                Text(
                                                  'Barcode Scanner Area',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: isWaitingForVerification ? Colors.red : Color(0xFFFF6B35),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  isWaitingForVerification 
                                                      ? 'Waiting for verification...'
                                                      : 'Drop items here to scan',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: isWaitingForVerification ? Colors.red : Colors.grey.shade600,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 15),
                                                Text(
                                                  'Tap scanned items to verify billing',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue.shade600,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        
                                        // Current item for verification - positioned in center
                                        if (currentItemForVerification != null)
                                          Positioned.fill(
                                            child: Center(
                                              child: GestureDetector(
                                                onTap: () => _handleItemTap(currentItemForVerification!),
                                                child: Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.yellow.shade100,
                                                    borderRadius: BorderRadius.circular(15),
                                                    border: Border.all(color: Colors.orange, width: 3),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.orange.withOpacity(0.3),
                                                        blurRadius: 10,
                                                        offset: const Offset(0, 5),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'CURRENT ITEM - Tap to Verify',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.orange.shade800,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      const SizedBox(height: 10),
                                                      Container(
                                                        width: 100,
                                                        height: 100,
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(15),
                                                          border: Border.all(color: Color(0xFFFF6B35), width: 3),
                                                          color: Colors.white,
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
                                                            Expanded(
                                                              child: Image.asset(
                                                                currentItemForVerification!.assetPath,
                                                                fit: BoxFit.contain,
                                                                errorBuilder: (context, error, stackTrace) {
                                                                  return Icon(
                                                                    Icons.shopping_cart,
                                                                    size: 40,
                                                                    color: Color(0xFFFF6B35),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                            const SizedBox(height: 5),
                                                            Text(
                                                              currentItemForVerification!.name,
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                                color: Color(0xFFFF6B35),
                                                              ),
                                                              textAlign: TextAlign.center,
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            Text(
                                                              '\$${currentItemForVerification!.price.toStringAsFixed(2)}',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color: Colors.green,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
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
                                  if (isWaitingForVerification)
                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(color: Colors.red, width: 2),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.lock,
                                                size: 50,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Please verify the current item first!',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                'Tap the yellow highlighted item to verify',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (availableItems.isNotEmpty && !isWaitingForVerification)
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
                                                  color: Color(0xFFFF6B35),
                                                  width: 3,
                                                ),
                                                color: Colors.white,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color(0xFFFF6B35).withOpacity(0.3),
                                                    blurRadius: 8,
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
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    item.name,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFFF6B35),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  Text(
                                                    '\$${item.price.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  if (availableItems.isEmpty && !isWaitingForVerification)
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'All items processed!',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
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
          if (scannedItems.isNotEmpty)
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
        ],
      ),
    );
  }
}
