import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';

class FruitMatchLevel3Game extends StatefulWidget {
  const FruitMatchLevel3Game({Key? key}) : super(key: key);

  @override
  _FruitMatchLevel3GameState createState() => _FruitMatchLevel3GameState();
}

class _FruitMatchLevel3GameState extends State<FruitMatchLevel3Game> with TickerProviderStateMixin {
  // Game variables
  List<SliceFruit> availableSlices = [];
  List<String> droppedSlices = [];
  String? draggedSlice;
  bool isGameComplete = false;
  int score = 0;
  int _seconds = 0;
  Timer? _timer;
  
  // Confetti controller
  late ConfettiController _confettiController;
  
  // Animation controller
  late AnimationController _bowlAnimationController;
  late Animation<double> _bowlScaleAnimation;
  
  // Bowl state
  String currentBowlImage = 'assets/Empty_bowl.png';
  
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
    
    // Initialize bowl animation
    _bowlAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _bowlScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bowlAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _initializeSlices();
    _startTimer();
  }
  
  void _initializeSlices() {
    availableSlices = [
      SliceFruit(name: 'Mango Slice', assetPath: 'assets/Mango_Slice.png'),
      SliceFruit(name: 'Papaya Slice', assetPath: 'assets/Papaw_slice.png'),
      SliceFruit(name: 'Banana Slice', assetPath: 'assets/Banan_Slice.png'),
    ];
    
    // Shuffle for variety
    availableSlices.shuffle();
    droppedSlices = [];
    currentBowlImage = 'assets/Empty_bowl.png';
    isGameComplete = false;
    score = 0;
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
  
  void _handleSliceDrop(String sliceName) {
    print('Dropped slice: $sliceName'); // Debug print
    setState(() {
      droppedSlices.add(sliceName);
      availableSlices.removeWhere((slice) => slice.name == sliceName);
      score += 10;
      
      // Update bowl image based on current dropped slice
      if (sliceName.contains('Mango')) {
        currentBowlImage = 'assets/Mango_Slice.png';
      } else if (sliceName.contains('Papaya')) {
        currentBowlImage = 'assets/Papaw_slice.png';
      } else if (sliceName.contains('Banana')) {
        currentBowlImage = 'assets/Banan_Slice.png';
      }
      
      // Animate bowl
      _bowlAnimationController.forward().then((_) {
        _bowlAnimationController.reverse();
      });
      
      // Trigger confetti
      _confettiController.play();
      
      // Check if game is complete
      if (droppedSlices.length >= 3) {
        isGameComplete = true;
        _showLevelCompleteDialog();
      }
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
              colors: [Colors.purple, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Level 3 Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Excellent! You mixed the fruit salad with a score of $score!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Amazing!',
                  style: TextStyle(
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
    // Reset orientation to portrait when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    _bowlAnimationController.dispose();
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
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
                // Header
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
                        'Mix Fruit Salad',
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
                              'Time: $_seconds',
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
                
                // Game area
                Expanded(
                  child: Row(
                    children: [
                      // Left side - Bowl
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          child: DragTarget<String>(
                            onAccept: (data) {
                              _handleSliceDrop(data);
                            },
                            builder: (context, candidateData, rejectedData) {
                              return ScaleTransition(
                                scale: _bowlScaleAnimation,
                                child: Container(
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
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Mix Fruit Salad',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.orange, width: 2),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.asset(
                                            currentBowlImage,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: Icon(Icons.restaurant, size: 30, color: Colors.grey),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Text(
                                        'Drop slices here',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Right side - Slices
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
                                'Available Slices',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Expanded(
                                child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 15,
                                    crossAxisSpacing: 15,
                                    childAspectRatio: 1.0,
                                  ),
                                  itemCount: availableSlices.length,
                                  itemBuilder: (context, index) {
                                    final slice = availableSlices[index];
                                    return Draggable<String>(
                                      data: slice.name,
                                      feedback: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: Colors.orange, width: 2),
                                          color: Colors.white,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(13),
                                          child: Image.asset(
                                            slice.assetPath,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: Colors.grey, width: 1),
                                          color: Colors.grey[300],
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: Colors.orange, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(13),
                                          child: Image.asset(
                                            slice.assetPath,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                              );
                                            },
                                          ),
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
                Colors.orange,
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

class SliceFruit {
  final String name;
  final String assetPath;
  
  SliceFruit({
    required this.name,
    required this.assetPath,
  });
}
