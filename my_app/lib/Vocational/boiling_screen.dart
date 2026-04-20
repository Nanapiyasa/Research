import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'tea_level3_game.dart';

class BoilingScreen extends StatefulWidget {
  final int initialTime;
  
  const BoilingScreen({Key? key, this.initialTime = 0}) : super(key: key);

  @override
  State<BoilingScreen> createState() => _BoilingScreenState();
}

class _BoilingScreenState extends State<BoilingScreen>
    with TickerProviderStateMixin {
  // Force landscape immediately
  _BoilingScreenState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  
  // Animation controllers
  late AnimationController _bubbleController;
  late AnimationController _steamController;
  late Animation<double> _bubbleAnimation;
  late Animation<double> _steamAnimation;
  
  // Confetti controller
  late ConfettiController _confettiController;
  
  // Game state
  bool isBoiling = false;
  bool isComplete = false;
  int boilingSeconds = 0;
  int _seconds = 0;
  Timer? _boilingTimer;
  Timer? _bubbleTimer;
  
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
    
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Initialize bubble animation
    _bubbleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bubbleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize steam animation
    _steamController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _steamAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _steamController,
      curve: Curves.easeInOut,
    ));
    
    // Mark animations as initialized
    _animationsInitialized = true;
    
    // Initialize timer with initial time
    _seconds = widget.initialTime;
    
    // Start boiling process
    _startBoiling();
    
    // Aggressive landscape orientation enforcement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }
  
  void _startBoiling() {
    setState(() {
      isBoiling = true;
      boilingSeconds = 0;
    });
    
    // Start bubble animation
    _bubbleController.repeat(reverse: true);
    
    // Start boiling timer
    _boilingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          boilingSeconds++;
          
          // Start steam animation after 5 seconds
          if (boilingSeconds == 5) {
            _steamController.repeat(reverse: true);
          }
          
          // Complete after 15 seconds
          if (boilingSeconds >= 15) {
            _boilingTimer?.cancel();
            _bubbleController.stop();
            _steamController.stop();
            isBoiling = false;
            isComplete = true;
            _confettiController.play();
          }
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
    
    _confettiController.dispose();
    _bubbleController.dispose();
    _steamController.dispose();
    _boilingTimer?.cancel();
    _bubbleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force landscape orientation at build time
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Additional aggressive landscape enforcement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
    
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
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Score: 10',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Time: ${boilingSeconds}s',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Message area
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isBoiling ? Icons.local_fire_department : Icons.check_circle,
                            color: isBoiling ? Colors.orange : Colors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isBoiling ? 'Water is Heating...' : 'Water is Boiling!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isBoiling ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isBoiling 
                            ? 'Please wait while the water heats up... ${boilingSeconds}/15 seconds'
                            : 'Perfect! Water is ready for tea making.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Main boiling area
                Expanded(
                  child: Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Kettle image
                          Center(
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.asset(
                                  'assets/Empty_Kettle.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Icon(
                                        Icons.kitchen,
                                        color: Colors.grey,
                                        size: 50,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          
                          // Bubbles animation
                          if (_animationsInitialized && isBoiling)
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _bubbleAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _bubbleAnimation.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.blue.withOpacity(0.3),
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          
                          // Steam animation
                          if (_animationsInitialized && boilingSeconds >= 2)
                            Positioned(
                              top: 50,
                              left: 0,
                              right: 0,
                              child: AnimatedBuilder(
                                animation: _steamAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _steamAnimation.value,
                                    child: const Column(
                                      children: [
                                        Icon(Icons.cloud, color: Colors.grey, size: 40),
                                        Icon(Icons.cloud, color: Colors.grey, size: 30),
                                        Icon(Icons.cloud, color: Colors.grey, size: 20),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Complete button
                if (isComplete)
                  Container(
                    margin: const EdgeInsets.all(20),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => TeaLevel3Game(initialTime: _seconds),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.3),
                      ),
                      child: const Text(
                        'Complete',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Confetti overlay
          if (isComplete)
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  particleDrag: 0.05,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.1,
                  shouldLoop: false,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
