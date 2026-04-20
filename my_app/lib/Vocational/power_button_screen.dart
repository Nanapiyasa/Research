import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'tea_level3_game.dart';

class PowerButtonScreen extends StatefulWidget {
  final int initialTime;
  
  const PowerButtonScreen({Key? key, this.initialTime = 0}) : super(key: key);

  @override
  _PowerButtonScreenState createState() => _PowerButtonScreenState();
}

class _PowerButtonScreenState extends State<PowerButtonScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _powerPressed = false;
  bool _showStove = false;

  @override
  void initState() {
    super.initState();
    
    // Force landscape orientation immediately
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Initialize slide animation for stove transition
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right
      end: Offset.zero, // End at center
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    // Keep landscape orientation when navigating to next level
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onPowerButtonPressed() {
    setState(() {
      _powerPressed = true;
    });
    
    // Start fade out animation for power button
    _fadeController.forward().then((_) {
      setState(() {
        _showStove = true;
      });
      
      // Ensure landscape orientation when stove appears
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      // Start slide in animation for stove
      _slideController.forward().then((_) {
        // Navigate to next level after a short delay
        Timer(const Duration(seconds: 2), () {
          _navigateToNextLevel();
        });
      });
    });
  }

  void _navigateToNextLevel() {
    // Keep landscape orientation for next level
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => TeaLevel3Game(initialTime: widget.initialTime),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force landscape orientation immediately and aggressively
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Add a small delay to ensure orientation is applied
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
    
    return WillPopScope(
      onWillPop: () async {
        // Allow back navigation
        return true;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/kitchen1.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Instructions text
                if (!_powerPressed)
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Water Filling Complete!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Now let\'s turn on the stove for the next step.\nTap the power button to start!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Power button (with fade animation)
                if (!_powerPressed)
                  Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: GestureDetector(
                        onTap: _onPowerButtonPressed,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(75),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(75),
                            child: Image.asset(
                              'assets/Power button.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(75),
                                  ),
                                  child: const Icon(
                                    Icons.power_settings_new,
                                    color: Colors.white,
                                    size: 80,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Stove (with slide animation)
                if (_showStove)
                  Positioned.fill(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 300,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.8),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.asset(
                                    'assets/stovetop.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: const Icon(
                                          Icons.local_fire_department,
                                          color: Colors.white,
                                          size: 100,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Stove is now ON!\nReady for cooking...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}
