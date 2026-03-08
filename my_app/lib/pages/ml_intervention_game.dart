// lib/pages/ml_intervention_game.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ml_intervention_model.dart';

class MLInterventionGame extends StatefulWidget {
  final String apiUrl;
  final Function(MLPredictionResult result) onPredictionComplete;

  const MLInterventionGame({
    Key? key,
    required this.apiUrl,
    required this.onPredictionComplete,
  }) : super(key: key);

  @override
  _MLInterventionGameState createState() => _MLInterventionGameState();
}

class _MLInterventionGameState extends State<MLInterventionGame>
    with TickerProviderStateMixin {
  // Game state
  late CosmicLevel _currentLevel;
  late GameStatistics _stats;
  late GameSessionData _currentSession;

  // UI state
  bool _showLevelSelect = true;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _gameCompleted = false;
  MLPredictionResult? _lastPrediction;

  // Game variables
  int _currentScore = 0;
  int _correctSequences = 0;
  int _totalSequences = 0;
  int _currentRound = 1;

  // Sequence memory
  List<CosmicSymbol> _targetSequence = [];
  List<CosmicSymbol> _userSequence = [];
  int _currentSequenceIndex = 0;
  bool _isShowingSequence = false;

  // Timers
  Stopwatch _gameTimer = Stopwatch();
  Timer? _countdownTimer;
  int _timeLeft = 60;
  Timer? _sequenceTimer;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  // Particle effects
  List<Particle> _particles = [];
  late Timer _particleTimer;

  @override
  void initState() {
    super.initState();
    _initializeGame();

    // Animation controllers
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Start animations
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();

    // Initialize particles
    _initParticles();
  }

  void _initializeGame() {
    _stats = GameStatistics(
      firstPlayed: DateTime.now(),
      lastPlayed: DateTime.now(),
    );
  }

  void _initParticles() {
    _particles = List.generate(20, (index) => Particle(
      x: Random().nextDouble() * 400,
      y: Random().nextDouble() * 800,
      speed: Random().nextDouble() * 2 + 1,
      size: Random().nextDouble() * 3 + 1,
      color: Colors.white.withOpacity(Random().nextDouble() * 0.3),
    ));

    _particleTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          for (var particle in _particles) {
            particle.y += particle.speed;
            if (particle.y > 800) {
              particle.y = 0;
              particle.x = Random().nextDouble() * 400;
            }
          }
        });
      }
    });
  }

  void _selectLevel(CosmicLevel level) {
    setState(() {
      _currentLevel = level;
      _showLevelSelect = false;
      _isPlaying = true;
      _startGame();
    });
  }

  void _startGame() {
    _gameTimer.reset();
    _gameTimer.start();
    _timeLeft = _currentLevel.timeLimit;
    _currentScore = _currentLevel.baseScore;
    _correctSequences = 0;
    _totalSequences = 0;
    _currentRound = 1;

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeLeft--;
        });
      }
      if (_timeLeft <= 0) {
        timer.cancel();
        _endGame();
      }
    });

    _startNewRound();
  }

  void _startNewRound() {
    setState(() {
      _isShowingSequence = true;
      _userSequence.clear();
      _currentSequenceIndex = 0;
      _generateSequence();
    });

    _showSequence();
  }

  void _generateSequence() {
    int length = min(
        _currentLevel.sequenceLength + (_currentRound - 1),
        8
    );

    _targetSequence = [];
    Random random = Random();

    for (int i = 0; i < length; i++) {
      int index = random.nextInt(CosmicSymbol.values.length);
      _targetSequence.add(CosmicSymbol.values[index]);
    }
  }

  Future<void> _showSequence() async {
    double speed = 0.8 / _currentLevel.speedMultiplier;

    for (int i = 0; i < _targetSequence.length; i++) {
      await Future.delayed(Duration(milliseconds: (500 * speed).round()));
      if (mounted) {
        setState(() {
          _currentSequenceIndex = i;
        });
      }
      _pulseController.forward(from: 0);
      await Future.delayed(Duration(milliseconds: (300 * speed).round()));
    }

    await Future.delayed(Duration(milliseconds: 200));
    if (mounted) {
      setState(() {
        _currentSequenceIndex = -1;
        _isShowingSequence = false;
      });
    }
  }

  void _onSymbolTap(CosmicSymbol symbol) {
    if (_isShowingSequence) return;

    setState(() {
      _userSequence.add(symbol);
      _totalSequences++;

      // Check if correct so far
      int index = _userSequence.length - 1;
      if (index < _targetSequence.length &&
          _userSequence[index] == _targetSequence[index]) {

        _showSuccessFeedback();

        // Check if sequence complete
        if (_userSequence.length == _targetSequence.length) {
          _correctSequences++;
          _currentScore += 100 * (_currentLevel.encoded + 1) * _currentRound;
          _currentRound++;

          _showRoundComplete();

          Future.delayed(Duration(seconds: 1), () {
            if (mounted) {
              _startNewRound();
            }
          });
        }
      } else {
        // Wrong symbol
        _showErrorFeedback();
        _endGame();
      }
    });
  }

  void _showSuccessFeedback() {
    _fadeController.forward(from: 0);

    // Create success particles
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          setState(() {
            _particles.add(Particle(
              x: Random().nextDouble() * 400,
              y: Random().nextDouble() * 800,
              speed: Random().nextDouble() * 3 + 2,
              size: Random().nextDouble() * 4 + 2,
              color: [Colors.green, Colors.yellow, Colors.cyan][Random().nextInt(3)]
                  .withOpacity(Random().nextDouble() * 0.5 + 0.3),
            ));
          });
        }
      });
    }
  }

  void _showErrorFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Wrong sequence! Game Over',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  void _showRoundComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.amber.shade700.withOpacity(0.9),
                  Colors.orange.shade900,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: Colors.yellow, size: 40),
                SizedBox(height: 8),
                Text(
                  'ROUND COMPLETE!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Round $_currentRound',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _currentRound / 5,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                  minHeight: 6,
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _endGame() {
    _gameTimer.stop();
    _countdownTimer?.cancel();
    _sequenceTimer?.cancel();

    _stats.totalSessions++;
    _stats.totalScore += _currentScore;
    _stats.totalTimeSpent += _gameTimer.elapsed.inSeconds;
    _stats.correctSequences += _correctSequences;
    _stats.totalSequences += _totalSequences;
    _stats.lastPlayed = DateTime.now();

    _stats.levelAttempts[_currentLevel] =
        (_stats.levelAttempts[_currentLevel] ?? 0) + 1;

    _currentSession = _stats.getCurrentSessionData(
      _gameTimer.elapsed.inSeconds,
      _currentScore,
      _currentLevel,
      _correctSequences,
      _totalSequences,
    );

    setState(() {
      _isPlaying = false;
      _gameCompleted = true;
      _isLoading = true;
    });

    _getPrediction();
  }

  Future<void> _getPrediction() async {
    try {
      final response = await http.post(
        Uri.parse('${widget.apiUrl}/predict-intervention'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(_currentSession.toJson()),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _lastPrediction = MLPredictionResult.fromJson(data);
          _isLoading = false;
        });

        widget.onPredictionComplete(_lastPrediction!);
        _showResultDialog();
      } else {
        throw Exception('Failed to get prediction');
      }
    } catch (e) {
      print('Prediction error: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog();
    }
  }

  // ENHANCED RESULT DIALOG WITH BETTER VISIBILITY
  void _showResultDialog() {
    if (_lastPrediction == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87, // Darker barrier
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E), // Dark blue-black
                  Color(0xFF16213E), // Slightly lighter dark blue
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _currentLevel.color.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _currentLevel.color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Background glow
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _currentLevel.color.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with rank
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              // Animated rank icon with glow
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _currentLevel.color.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: RotationTransition(
                                  turns: _rotateAnimation,
                                  child: Icon(
                                    _currentLevel.icon,
                                    size: 60,
                                    color: _currentLevel.color,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),

                              // Rank badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _currentLevel.color.withOpacity(0.3),
                                      _currentLevel.color.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: _currentLevel.color,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _currentLevel.color.withOpacity(0.3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _currentLevel.displayName.toUpperCase(),
                                  style: TextStyle(
                                    color: _currentLevel.color,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Stats cards - Improved visibility
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF0F0F1A), // Solid dark background
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildEnhancedStatItem(
                                'Score',
                                '$_currentScore',
                                Icons.stars,
                                Colors.amber,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              _buildEnhancedStatItem(
                                'Rounds',
                                '$_currentRound',
                                Icons.flag,
                                Colors.blue.shade300,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              _buildEnhancedStatItem(
                                'Time',
                                '${_gameTimer.elapsed.inSeconds}s',
                                Icons.timer,
                                Colors.orange.shade300,
                              ),
                            ],
                          ),
                        ),

                        // Accuracy section - Improved
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF0F0F1A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.analytics,
                                        color: Colors.green.shade400,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Accuracy Rate',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.green.shade400,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${_totalSequences > 0 ? (_correctSequences / _totalSequences * 100).toStringAsFixed(1) : '0'}%',
                                      style: TextStyle(
                                        color: Colors.green.shade400,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: _totalSequences > 0
                                    ? _correctSequences / _totalSequences
                                    : 0,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.green.shade400,
                                ),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${_correctSequences} correct out of $_totalSequences sequences',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ML Prediction section - Greatly improved visibility
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _lastPrediction!.probabilityColor.withOpacity(0.3),
                                Color(0xFF0F0F1A),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _lastPrediction!.probabilityColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _lastPrediction!.probabilityColor.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _lastPrediction!.probabilityColor.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.psychology,
                                      color: _lastPrediction!.probabilityColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AI Cognitive Analysis',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Machine Learning Assessment',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),

                              // Probability indicator
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Confidence Score',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${(_lastPrediction!.probability * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: _lastPrediction!.probabilityColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Stack(
                                children: [
                                  Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: _lastPrediction!.probability,
                                    child: Container(
                                      height: 12,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _lastPrediction!.probabilityColor.withOpacity(0.7),
                                            _lastPrediction!.probabilityColor,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _lastPrediction!.probabilityColor,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),

                              // Recommendation
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFF0A0A14),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'RECOMMENDATION',
                                      style: TextStyle(
                                        color: _lastPrediction!.probabilityColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      _lastPrediction!.recommendation,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        // Action buttons - Enhanced
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _showLevelSelect = true;
                                    _gameCompleted = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentLevel.color,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                  shadowColor: _currentLevel.color.withOpacity(0.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.refresh, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'PLAY AGAIN',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.exit_to_app, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'EXIT',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Enhanced stat item with better visibility - ONLY ONE DECLARATION
  Widget _buildEnhancedStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text('Error', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Text(
            'Failed to get prediction. Please try again.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _showLevelSelect = true;
                });
              },
              child: Text('OK', style: TextStyle(color: Colors.blue, fontSize: 13)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showLevelSelect) {
      return _buildLevelSelection();
    }

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_gameCompleted) {
      return _buildGameCompleteScreen();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Particle background
          _buildParticleBackground(),

          // Main game content
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.black,
                  Colors.blue.shade900.withOpacity(0.5),
                  Colors.purple.shade900.withOpacity(0.3),
                ],
                stops: [0.3, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header with game stats
                  _buildGameHeader(),

                  // Game area
                  Expanded(
                    child: _buildGameArea(),
                  ),

                  // Symbol buttons
                  _buildSymbolButtons(),

                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelection() {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.black, Colors.blue.shade900, Colors.purple.shade900],
                stops: [0.2, 0.6, 1.0],
              ),
            ),
          ),

          // Twinkling stars
          _buildStarField(),

          // Level cards with back button
          SafeArea(
            child: Column(
              children: [
                // Back button and title row
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Back button to previous page
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                          onPressed: () {
                            // Navigate back to previous page (Drowsiness Detection)
                            Navigator.pop(context);
                          },
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(),
                          iconSize: 20,
                        ),
                      ),
                      SizedBox(width: 8),
                      // Title
                      Expanded(
                        child: Text(
                          'Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable level cards
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        RotationTransition(
                          turns: _rotateAnimation,
                          child: Icon(
                            Icons.rocket_launch,
                            size: 60,
                            color: Colors.cyan.shade300,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'COSMIC\nCODEBREAKER',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [Colors.cyan, Colors.purple, Colors.amber],
                              ).createShader(Rect.fromLTWH(0, 0, 200, 60)),
                          ),
                        ),
                        Text(
                          'Test Your Memory',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Level cards
                        ...CosmicLevel.values.map((level) =>
                            _buildLevelCard(level)
                        ).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(CosmicLevel level) {
    return GestureDetector(
      onTap: () => _selectLevel(level),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              level.color.withOpacity(0.3),
              level.color.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: level.color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: level.color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Animated pulse effect
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: level.color.withOpacity(0.5), width: 1),
                ),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: level.color.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: level.color),
                    ),
                    child: Icon(
                      level.icon,
                      color: level.color,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Seq: ${level.sequenceLength} • ${level.timeLimit}s',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: level.color,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameHeader() {
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _currentLevel.color.withOpacity(0.3),
            Colors.black54,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _currentLevel.color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Level info
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(_currentLevel.icon, color: _currentLevel.color, size: 16),
                SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentLevel.displayName,
                        style: TextStyle(
                          color: _currentLevel.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'R$_currentRound',
                        style: TextStyle(color: Colors.white70, fontSize: 8),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Timer
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _timeLeft < 10 ? Colors.red : _currentLevel.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, color: Colors.white, size: 10),
                SizedBox(width: 2),
                Text(
                  '$_timeLeft',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Expanded(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.stars, color: Colors.amber, size: 10),
                SizedBox(width: 2),
                Flexible(
                  child: Text(
                    '$_currentScore',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    if (_isShowingSequence) {
      if (_currentSequenceIndex >= 0 &&
          _currentSequenceIndex < _targetSequence.length) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Watch...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 16),
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _targetSequence[_currentSequenceIndex].color,
                        _targetSequence[_currentSequenceIndex].color.withOpacity(0.3),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _targetSequence[_currentSequenceIndex].color,
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _targetSequence[_currentSequenceIndex].emoji,
                      style: TextStyle(fontSize: 36),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                _targetSequence[_currentSequenceIndex].name,
                style: TextStyle(
                  color: _targetSequence[_currentSequenceIndex].color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      } else {
        return Center(
          child: Text(
            'Get Ready...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        );
      }
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your Turn!',
              style: TextStyle(
                color: _currentLevel.color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${_userSequence.length}/${_targetSequence.length}',
              style: TextStyle(
                color: _currentLevel.color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSymbolButtons() {
    return Container(
      height: 140,
      padding: EdgeInsets.all(8),
      child: GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.9,
        physics: NeverScrollableScrollPhysics(),
        children: CosmicSymbol.values.map((symbol) {
          return ScaleTransition(
            scale: _pulseAnimation,
            child: GestureDetector(
              onTap: () => _onSymbolTap(symbol),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      symbol.color.withOpacity(0.3),
                      symbol.color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: symbol.color, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: symbol.color.withOpacity(0.2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      symbol.emoji,
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 2),
                    Text(
                      symbol.name,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildParticleBackground() {
    return CustomPaint(
      painter: ParticlePainter(_particles),
      child: Container(),
    );
  }

  Widget _buildStarField() {
    return CustomPaint(
      painter: StarPainter(),
      child: Container(),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.black, Colors.blue.shade900],
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  turns: _rotateAnimation,
                  child: Icon(
                    Icons.rocket_launch,
                    size: 50,
                    color: Colors.cyan,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Analyzing your cosmic journey...',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCompleteScreen() {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.black, Colors.purple.shade900],
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Mission Complete!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: [Colors.amber, Colors.cyan],
                      ).createShader(Rect.fromLTWH(0, 0, 160, 30)),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                Text(
                  'Score: $_currentScore',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showLevelSelect = true;
                      _gameCompleted = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: Size(0, 36),
                  ),
                  child: Text('Play Again', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    _countdownTimer?.cancel();
    _sequenceTimer?.cancel();
    _particleTimer.cancel();
    super.dispose();
  }
}

// Particle class with proper initialization
class Particle {
  double x;
  double y;
  double speed;
  double size;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      Paint paint = Paint()..color = particle.color;
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Random random = Random(42);
    Paint paint = Paint()..color = Colors.white.withOpacity(0.5);

    for (int i = 0; i < 50; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double radius = random.nextDouble() * 1.5 + 0.5;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}