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
  final GameType gameType;

  const MLInterventionGame({
    Key? key,
    required this.apiUrl,
    required this.onPredictionComplete,
    this.gameType = GameType.memoryMatch,
  }) : super(key: key);

  @override
  _MLInterventionGameState createState() => _MLInterventionGameState();
}

class _MLInterventionGameState extends State<MLInterventionGame> with TickerProviderStateMixin {
  // Game state
  late GameType _currentGame;
  late DifficultyLevel _currentDifficulty;
  late GameStatistics _stats;
  late GameSessionData _currentSession;

  // UI state
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _showDifficultySelect = true;
  MLPredictionResult? _lastPrediction;

  // Game-specific variables
  List<Map<String, dynamic>> _memoryCards = [];
  int _selectedCardIndex = -1;
  int _matchedPairs = 0;
  int _attempts = 0;
  Stopwatch _gameTimer = Stopwatch();
  Timer? _countdownTimer;
  int _timeLeft = 60;

  // Pattern recognition
  List<Color> _pattern = [];
  List<Color> _userPattern = [];
  int _patternIndex = 0;

  // Sequence memory
  List<int> _sequence = [];
  List<int> _userSequence = [];
  int _sequenceIndex = 0;

  // Reaction time
  DateTime _reactionStart = DateTime.now();
  bool _waitingForReaction = false;
  List<int> _reactionTimes = [];

  // Animations
  late AnimationController _gameController;
  late Animation<double> _gameAnimation;

  @override
  void initState() {
    super.initState();
    _currentGame = widget.gameType;
    _currentDifficulty = DifficultyLevel.medium;

    _gameController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _gameAnimation = CurvedAnimation(
      parent: _gameController,
      curve: Curves.elasticOut,
    );

    _stats = GameStatistics(
      firstPlayed: DateTime.now(),
      lastPlayed: DateTime.now(),
    );
  }

  void _selectDifficulty(DifficultyLevel difficulty) {
    setState(() {
      _currentDifficulty = difficulty;
      _showDifficultySelect = false;
      _isPlaying = true;
      _initializeGame();
    });
  }

  void _initializeGame() {
    _gameTimer.reset();
    _gameTimer.start();
    _timeLeft = _getTimeLimit();

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0 || _isGameComplete()) {
        timer.cancel();
        _endGame();
      }
    });

    switch (_currentGame) {
      case GameType.memoryMatch:
        _initializeMemoryMatch();
        break;
      case GameType.patternRecognition:
        _initializePatternRecognition();
        break;
      case GameType.sequenceMemory:
        _initializeSequenceMemory();
        break;
      case GameType.reactionTime:
        _initializeReactionTime();
        break;
      case GameType.problemSolving:
        _initializeProblemSolving();
        break;
    }
  }

  void _initializeMemoryMatch() {
    List<String> emojis = ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼'];
    int pairCount = _getPairCount();

    _memoryCards = [];
    for (int i = 0; i < pairCount; i++) {
      _memoryCards.add({
        'id': i * 2,
        'emoji': emojis[i % emojis.length],
        'isFlipped': false,
        'isMatched': false,
        'pairId': i,
      });
      _memoryCards.add({
        'id': i * 2 + 1,
        'emoji': emojis[i % emojis.length],
        'isFlipped': false,
        'isMatched': false,
        'pairId': i,
      });
    }
    _memoryCards.shuffle();
  }

  void _initializePatternRecognition() {
    List<Color> colors = [
      Colors.red, Colors.blue, Colors.green, Colors.yellow,
      Colors.purple, Colors.orange, Colors.pink, Colors.teal,
    ];

    int patternLength = _getPatternLength();
    _pattern = [];
    _userPattern = [];

    Random random = Random();
    for (int i = 0; i < patternLength; i++) {
      _pattern.add(colors[random.nextInt(colors.length)]);
    }

    _patternIndex = 0;

    // Show pattern
    Future.delayed(Duration(milliseconds: 500), () {
      _animatePattern();
    });
  }

  Future<void> _animatePattern() async {
    for (int i = 0; i < _pattern.length; i++) {
      await Future.delayed(Duration(milliseconds: 500));
      setState(() {
        _patternIndex = i;
      });
      await Future.delayed(Duration(milliseconds: 300));
      setState(() {
        _patternIndex = -1;
      });
    }
  }

  void _initializeSequenceMemory() {
    int sequenceLength = _getSequenceLength();
    _sequence = [];
    _userSequence = [];

    Random random = Random();
    for (int i = 0; i < sequenceLength; i++) {
      _sequence.add(random.nextInt(9) + 1);
    }

    _sequenceIndex = 0;

    // Show sequence
    Future.delayed(Duration(milliseconds: 500), () {
      _animateSequence();
    });
  }

  Future<void> _animateSequence() async {
    for (int i = 0; i < _sequence.length; i++) {
      await Future.delayed(Duration(milliseconds: 500));
      setState(() {
        _sequenceIndex = _sequence[i];
      });
      await Future.delayed(Duration(milliseconds: 300));
      setState(() {
        _sequenceIndex = 0;
      });
    }
  }

  void _initializeReactionTime() {
    _reactionTimes = [];
    _waitingForReaction = false;
    _nextReactionTest();
  }

  void _nextReactionTest() {
    if (_reactionTimes.length >= 5) {
      _endGame();
      return;
    }

    Future.delayed(Duration(milliseconds: Random().nextInt(3000) + 1000), () {
      if (mounted) {
        setState(() {
          _waitingForReaction = true;
          _reactionStart = DateTime.now();
        });
      }
    });
  }

  void _handleReactionTap() {
    if (!_waitingForReaction) return;

    int reactionTime = DateTime.now().difference(_reactionStart).inMilliseconds;
    setState(() {
      _reactionTimes.add(reactionTime);
      _waitingForReaction = false;
    });
    _nextReactionTest();
  }

  void _initializeProblemSolving() {
    // Simple math problems
    // Will be implemented in game logic
  }

  void _onMemoryCardTap(int index) {
    if (_memoryCards[index]['isMatched'] || _memoryCards[index]['isFlipped']) return;

    setState(() {
      _memoryCards[index]['isFlipped'] = true;
      _attempts++;

      if (_selectedCardIndex == -1) {
        _selectedCardIndex = index;
      } else {
        _checkMatch(index);
      }
    });
  }

  void _checkMatch(int secondIndex) {
    final firstCard = _memoryCards[_selectedCardIndex];
    final secondCard = _memoryCards[secondIndex];

    if (firstCard['pairId'] == secondCard['pairId']) {
      // Match found
      setState(() {
        firstCard['isMatched'] = true;
        secondCard['isMatched'] = true;
        _matchedPairs++;
        _selectedCardIndex = -1;

        // Update stats
        _stats.totalScore += 10 * (_currentDifficulty.encoded + 1);
      });

      if (_isGameComplete()) {
        _endGame();
      }
    } else {
      // No match
      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            firstCard['isFlipped'] = false;
            secondCard['isFlipped'] = false;
            _selectedCardIndex = -1;
          });
        }
      });
    }
  }

  void _onPatternColorTap(Color color) {
    if (_patternIndex != -1) return;

    setState(() {
      _userPattern.add(color);
      _attempts++;
    });

    if (_userPattern.length == _pattern.length) {
      _checkPatternMatch();
    }
  }

  void _checkPatternMatch() {
    bool isCorrect = true;
    for (int i = 0; i < _pattern.length; i++) {
      if (_pattern[i] != _userPattern[i]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      _stats.totalScore += 15 * (_currentDifficulty.encoded + 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Pattern Correct!'), backgroundColor: Colors.green),
      );
    }

    _endGame();
  }

  void _onSequenceTap(int number) {
    if (_sequenceIndex != 0) return;

    setState(() {
      _userSequence.add(number);
      _attempts++;
    });

    if (_userSequence.length == _sequence.length) {
      _checkSequenceMatch();
    }
  }

  void _checkSequenceMatch() {
    bool isCorrect = true;
    for (int i = 0; i < _sequence.length; i++) {
      if (_sequence[i] != _userSequence[i]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      _stats.totalScore += 20 * (_currentDifficulty.encoded + 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Sequence Correct!'), backgroundColor: Colors.green),
      );
    }

    _endGame();
  }

  bool _isGameComplete() {
    switch (_currentGame) {
      case GameType.memoryMatch:
        return _matchedPairs == _memoryCards.length ~/ 2;
      case GameType.patternRecognition:
        return _userPattern.length == _pattern.length;
      case GameType.sequenceMemory:
        return _userSequence.length == _sequence.length;
      case GameType.reactionTime:
        return _reactionTimes.length >= 5;
      case GameType.problemSolving:
        return true;
    }
  }

  void _endGame() {
    _gameTimer.stop();
    _countdownTimer?.cancel();

    // Update statistics
    _stats.totalSessions++;
    _stats.totalTimeSpent += _gameTimer.elapsed.inSeconds;
    _stats.lastPlayed = DateTime.now();

    _stats.gamesPlayed[_currentGame] = (_stats.gamesPlayed[_currentGame] ?? 0) + 1;
    _stats.difficultyAttempts[_currentDifficulty] =
        (_stats.difficultyAttempts[_currentDifficulty] ?? 0) + 1;

    _currentSession = GameSessionData(
      timeSec: _gameTimer.elapsed.inSeconds,
      numberOfTimesPlayed: _stats.totalSessions,
      score: _stats.totalScore,
      difficultyLevel: _currentDifficulty,
      gameType: _currentGame,
      timestamp: DateTime.now(),
    );

    setState(() {
      _isPlaying = false;
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
        _showPredictionDialog();
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

  void _showPredictionDialog() {
    if (_lastPrediction == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                _lastPrediction!.needsIntervention
                    ? Icons.warning
                    : Icons.check_circle,
                color: _lastPrediction!.probabilityColor,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _lastPrediction!.interventionMessage,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _lastPrediction!.probabilityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Intervention Probability',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _lastPrediction!.probabilityText,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _lastPrediction!.probabilityColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.blue.shade700),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Recommendation',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(_lastPrediction!.recommendation),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _showDifficultySelect = true;
                });
              },
              child: Text('Play Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('Failed to get prediction. Please try again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _showDifficultySelect = true;
                });
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  int _getPairCount() {
    switch (_currentDifficulty) {
      case DifficultyLevel.veryEasy:
        return 4;
      case DifficultyLevel.easy:
        return 6;
      case DifficultyLevel.medium:
        return 8;
      case DifficultyLevel.hard:
        return 10;
      case DifficultyLevel.veryHard:
        return 12;
    }
  }

  int _getPatternLength() {
    switch (_currentDifficulty) {
      case DifficultyLevel.veryEasy:
        return 3;
      case DifficultyLevel.easy:
        return 4;
      case DifficultyLevel.medium:
        return 5;
      case DifficultyLevel.hard:
        return 6;
      case DifficultyLevel.veryHard:
        return 7;
    }
  }

  int _getSequenceLength() {
    switch (_currentDifficulty) {
      case DifficultyLevel.veryEasy:
        return 4;
      case DifficultyLevel.easy:
        return 5;
      case DifficultyLevel.medium:
        return 6;
      case DifficultyLevel.hard:
        return 7;
      case DifficultyLevel.veryHard:
        return 8;
    }
  }

  int _getTimeLimit() {
    switch (_currentDifficulty) {
      case DifficultyLevel.veryEasy:
        return 120;
      case DifficultyLevel.easy:
        return 90;
      case DifficultyLevel.medium:
        return 60;
      case DifficultyLevel.hard:
        return 45;
      case DifficultyLevel.veryHard:
        return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showDifficultySelect) {
      return _buildDifficultySelection();
    }

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentGame.displayName),
        backgroundColor: _currentGame.color,
        elevation: 0,
        actions: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // FIXED: Added mainAxisSize.min
              children: [
                Icon(Icons.timer, size: 16),
                SizedBox(width: 4),
                Text('$_timeLeft s'),
                SizedBox(width: 12),
                Icon(Icons.stars, size: 16),
                SizedBox(width: 4),
                Text('${_stats.totalScore}'),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _currentGame.color.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _buildGameContent(),
      ),
    );
  }

  Widget _buildDifficultySelection() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Difficulty'),
        backgroundColor: _currentGame.color,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _currentGame.color.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _currentGame.icon,
                  size: 80,
                  color: _currentGame.color,
                ),
                SizedBox(height: 20),
                Text(
                  _currentGame.displayName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _currentGame.color,
                  ),
                ),
                SizedBox(height: 40),
                ...DifficultyLevel.values.map((level) =>
                    _buildDifficultyButton(level)
                ).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(DifficultyLevel level) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _selectDifficulty(level),
        style: ElevatedButton.styleFrom(
          backgroundColor: level.color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(level.icon),
            SizedBox(width: 10),
            Text(
              level.displayName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_currentGame.color),
            ),
            SizedBox(height: 20),
            Text(
              'Analyzing your performance...',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Getting personalized recommendations',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameContent() {
    switch (_currentGame) {
      case GameType.memoryMatch:
        return _buildMemoryMatchGame();
      case GameType.patternRecognition:
        return _buildPatternRecognitionGame();
      case GameType.sequenceMemory:
        return _buildSequenceMemoryGame();
      case GameType.reactionTime:
        return _buildReactionTimeGame();
      case GameType.problemSolving:
        return _buildProblemSolvingGame();
    }
  }

  Widget _buildMemoryMatchGame() {
    int crossAxisCount = _getPairCount() <= 6 ? 3 : 4;

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Match the pairs!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Pairs matched: $_matchedPairs/${_memoryCards.length ~/ 2}',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _memoryCards.length,
              itemBuilder: (context, index) {
                return _buildMemoryCard(_memoryCards[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(Map<String, dynamic> card) {
    return GestureDetector(
      onTap: () => _onMemoryCardTap(card['id']),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card['isMatched']
              ? Colors.green.withOpacity(0.3)
              : card['isFlipped']
              ? Colors.white
              : _currentGame.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: card['isMatched'] ? Colors.green : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: card['isMatched']
              ? Icon(Icons.check_circle, color: Colors.green, size: 30)
              : card['isFlipped']
              ? Text(
            card['emoji'],
            style: TextStyle(fontSize: 30),
          )
              : Icon(
            Icons.help_outline,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildPatternRecognitionGame() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Watch the pattern, then repeat it!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          if (_patternIndex >= 0 && _patternIndex < _pattern.length)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _pattern[_patternIndex],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _pattern[_patternIndex].withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          SizedBox(height: 30),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              children: [
                Colors.red, Colors.blue, Colors.green, Colors.yellow,
                Colors.purple, Colors.orange, Colors.pink, Colors.teal,
              ].map((color) {
                return GestureDetector(
                  onTap: () => _onPatternColorTap(color),
                  child: Container(
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getColorName(color),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSequenceMemoryGame() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Remember the sequence!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          if (_sequenceIndex > 0)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _currentGame.color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$_sequenceIndex',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          SizedBox(height: 30),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 1,
              children: List.generate(9, (index) {
                int number = index + 1;
                return GestureDetector(
                  onTap: () => _onSequenceTap(number),
                  child: Container(
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _userSequence.contains(number)
                          ? Colors.green
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _currentGame.color,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _userSequence.contains(number)
                              ? Colors.white
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionTimeGame() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Tap when the circle turns green!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Reaction ${_reactionTimes.length + 1}/5',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          SizedBox(height: 40),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _handleReactionTap,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _waitingForReaction ? Colors.green : Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: (_waitingForReaction ? Colors.green : Colors.red)
                            .withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _waitingForReaction ? 'TAP!' : 'Wait...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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

  Widget _buildProblemSolvingGame() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Coming Soon!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            'Problem Solving games will be available in the next update.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: _endGame,
            child: Text('Complete Game'),
          ),
        ],
      ),
    );
  }

  String _getColorName(Color color) {
    if (color == Colors.red) return 'RED';
    if (color == Colors.blue) return 'BLUE';
    if (color == Colors.green) return 'GREEN';
    if (color == Colors.yellow) return 'YELLOW';
    if (color == Colors.purple) return 'PURPLE';
    if (color == Colors.orange) return 'ORANGE';
    if (color == Colors.pink) return 'PINK';
    if (color == Colors.teal) return 'TEAL';
    return '';
  }

  @override
  void dispose() {
    _gameController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }
}