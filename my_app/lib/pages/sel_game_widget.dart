// lib/pages/sel_game_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sel_game_model.dart';
import 'sel_game_data.dart';
import 'sel_chatbot_widget.dart';

class SELGameWidget extends StatefulWidget {
  final String apiUrl;
  final Function(SELGameStats stats, String predictedLevel) onGameComplete;

  const SELGameWidget({
    Key? key,
    required this.apiUrl,
    required this.onGameComplete,
  }) : super(key: key);

  @override
  _SELGameWidgetState createState() => _SELGameWidgetState();
}

class _SELGameWidgetState extends State<SELGameWidget> with TickerProviderStateMixin {
  // Game state
  late SELGameLevel _selectedLevel;
  late List<SELScenario> _levelScenarios;
  late SELGameStats _stats;

  // UI state
  int _currentScenarioIndex = 0;
  int? _selectedOptionIndex;
  bool _showFeedback = false;
  bool _isLoading = false;
  String? _predictedLevel;

  // Animations
  late AnimationController _feedbackController;
  late AnimationController _confettiController;
  late Animation<double> _feedbackAnimation;

  // Level selection
  bool _showLevelSelection = true;
  Map<SELGameLevel, int> _levelProgress = {};

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
  }

  void _startGame(SELGameLevel level) {
    _selectedLevel = level;
    _levelScenarios = SELGameData.getScenariosByLevel(level)..shuffle();

    _stats = SELGameStats(
      startTime: DateTime.now(),
      gameLevel: level,
      totalScenarios: _levelScenarios.length,
    );

    setState(() {
      _showLevelSelection = false;
      _currentScenarioIndex = 0;
    });
  }

  void _selectOption(int index) {
    if (_showFeedback || _isLoading) return;

    final scenario = _levelScenarios[_currentScenarioIndex];
    final option = scenario.options[index];
    final responseTime = DateTime.now().difference(_stats.startTime);

    setState(() {
      _selectedOptionIndex = index;
      _showFeedback = true;

      _stats.responseTimes.add(responseTime);
      _stats.scenariosCompleted++;

      _stats.skillAttempts[scenario.skill] =
          (_stats.skillAttempts[scenario.skill] ?? 0) + 1;

      if (option.isCorrect) {
        _stats.correctAnswers++;
        _stats.totalXP += scenario.xpReward;
        _stats.score += 10;

        _stats.skillScores[scenario.skill] =
            (_stats.skillScores[scenario.skill] ?? 0) + 1;

        _confettiController.forward(from: 0);
      }
    });

    _feedbackController.forward(from: 0);
  }

  void _nextScenario() {
    if (_currentScenarioIndex < _levelScenarios.length - 1) {
      setState(() {
        _currentScenarioIndex++;
        _selectedOptionIndex = null;
        _showFeedback = false;
      });
    } else {
      _completeGame();
    }
  }

  Future<void> _completeGame() async {
    setState(() {
      _isLoading = true;
      _stats.endTime = DateTime.now();
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.apiUrl}/predict-level'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(_stats.toPredictionData()),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _predictedLevel = data['predicted_level'] ?? 'Intermediate';
        });

        widget.onGameComplete(_stats, _predictedLevel!);
        _showCompletionDialog();
      } else {
        throw Exception('Failed to get prediction');
      }
    } catch (e) {
      print('Prediction error: $e');
      setState(() {
        _predictedLevel = 'Intermediate';
      });
      widget.onGameComplete(_stats, 'Intermediate');
      _showCompletionDialog();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCompletionDialog() {
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
              Icon(Icons.emoji_events, color: Colors.amber, size: 30),
              SizedBox(width: 8),
              Text('Level Complete! 🎉'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _selectedLevel.color.withOpacity(0.2),
                        _selectedLevel.color.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedLevel.icon,
                        color: _selectedLevel.color,
                        size: 40,
                      ),
                      SizedBox(width: 10),
                      Text(
                        _selectedLevel.displayName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _selectedLevel.color,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _buildResultRow(
                  'Total XP',
                  '${_stats.totalXP}',
                  Icons.star,
                  Colors.amber,
                ),
                _buildResultRow(
                  'Correct Answers',
                  '${_stats.correctAnswers}/${_stats.totalScenarios}',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildResultRow(
                  'Accuracy',
                  '${_stats.accuracy.toStringAsFixed(0)}%',
                  Icons.analytics,
                  Colors.blue,
                ),
                _buildResultRow(
                  'Average Time',
                  '${_stats.averageResponseTime.toStringAsFixed(1)}s',
                  Icons.timer,
                  Colors.orange,
                ),
                SizedBox(height: 16),
                Text(
                  '🌟 SEL Level: $_predictedLevel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showChatbot();
              },
              icon: Icon(Icons.chat),
              label: Text('Chat with Bot'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _showLevelSelection = true;
                });
              },
              icon: Icon(Icons.replay),
              label: Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('SEL Assistant'),
            backgroundColor: Colors.teal,
          ),
          body: SELChatbotWidget(
            apiUrl: widget.apiUrl,
            userLevel: _predictedLevel ?? 'Intermediate',
            userStats: _stats,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showLevelSelection) {
      return _buildLevelSelectionScreen();
    }

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    final scenario = _levelScenarios[_currentScenarioIndex];
    final progress = ((_currentScenarioIndex + 1) / _levelScenarios.length * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
      ),
      child: Column(
        children: [
          _buildGameHeader(progress, scenario),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildScenarioCard(scenario),
                  SizedBox(height: 25),
                  _buildOptionsList(scenario),
                  if (_showFeedback) _buildFeedbackCard(scenario),
                ],
              ),
            ),
          ),
          if (_showFeedback) _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildLevelSelectionScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.purple.shade100, Colors.blue.shade100],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                size: 80,
                color: Colors.purple.shade700,
              ),
              SizedBox(height: 20),
              Text(
                'Choose Your Level',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade800,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Each level has different challenges!',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              SizedBox(height: 40),
              ...SELGameLevel.values.map((level) => _buildLevelCard(level)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(SELGameLevel level) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _startGame(level),
        style: ElevatedButton.styleFrom(
          backgroundColor: level.color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        child: Row(
          children: [
            Icon(level.icon, size: 30),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.displayName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${level.scenariosCount} scenarios • +${level.timeBonus} XP bonus',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Analyzing your emotional intelligence...',
            style: TextStyle(fontSize: 16, color: Colors.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildGameHeader(int progress, SELScenario scenario) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(
                        ' ${_stats.totalXP} XP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.blue, size: 16),
                      Text(
                        ' ${_stats.accuracy.toStringAsFixed(0)}%',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scenario.skill.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scenario.skill.color),
                ),
                child: Row(
                  children: [
                    Text(
                      scenario.skill.emoji,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(width: 4),
                    Text(
                      scenario.skill.displayName,
                      style: TextStyle(
                        color: scenario.skill.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_selectedLevel.color),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level: ${_selectedLevel.displayName}',
                style: TextStyle(color: _selectedLevel.color),
              ),
              Text(
                '${_currentScenarioIndex + 1}/${_levelScenarios.length}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(SELScenario scenario) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scenario.skill.color.withOpacity(0.3),
                  scenario.skill.color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  scenario.imageAsset,
                  style: TextStyle(fontSize: 48),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            scenario.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade900,
            ),
          ),
          SizedBox(height: 12),
          Text(
            scenario.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsList(SELScenario scenario) {
    return Column(
      children: List.generate(scenario.options.length, (index) {
        final option = scenario.options[index];
        final isSelected = _selectedOptionIndex == index;
        final showResult = _showFeedback && isSelected;

        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showFeedback ? null : () => _selectOption(index),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _getOptionColor(index, option.isCorrect, showResult),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected
                        ? Colors.purple
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: option.icon != null
                            ? scenario.skill.color.withOpacity(0.2)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        option.icon ?? Icons.help_outline,
                        color: scenario.skill.color,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        option.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (showResult)
                      Icon(
                        option.isCorrect ? Icons.check_circle : Icons.cancel,
                        color: option.isCorrect ? Colors.green : Colors.red,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _getOptionColor(int index, bool isCorrect, bool showResult) {
    if (!showResult) return Colors.white;
    if (isCorrect) return Colors.green.shade50;
    return Colors.red.shade50;
  }

  Widget _buildFeedbackCard(SELScenario scenario) {
    final selectedOption = scenario.options[_selectedOptionIndex!];

    return FadeTransition(
      opacity: _feedbackAnimation,
      child: Container(
        margin: EdgeInsets.only(top: 20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: selectedOption.isCorrect
                ? [Colors.green.shade100, Colors.green.shade50]
                : [Colors.orange.shade100, Colors.orange.shade50],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selectedOption.isCorrect ? Colors.green : Colors.orange,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  selectedOption.isCorrect ? Icons.celebration : Icons.emoji_objects,
                  color: selectedOption.isCorrect ? Colors.green : Colors.orange,
                  size: 30,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedOption.isCorrect ? '🌟 Great Choice!' : '💭 Good Try!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: selectedOption.isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              selectedOption.explanation,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '💡 Tip: ${scenario.feedback}',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      padding: EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: _nextScenario,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedLevel.color,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currentScenarioIndex < _levelScenarios.length - 1
                  ? 'Next Scenario'
                  : 'Complete Level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _confettiController.dispose();
    super.dispose();
  }
}