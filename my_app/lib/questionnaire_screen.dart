import 'package:flutter/material.dart';
import 'game_menu_new.dart';
import 'model_service.dart';

// Question model
class Question {
  final String questionText;
  final List<String> options;

  Question({required this.questionText, required this.options});
}

// Questionnaire Screen
class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen>
    with TickerProviderStateMixin {
  int currentQuestionIndex = 0;
  List<String> selectedAnswers = List.filled(9, '');
  late AnimationController _completionAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<Question> questions = [
    Question(questionText: "Do you like helping peoples?", options: ["1", "2", "3", "4", "5"]),
    Question(
      questionText: "Do you like arranging or organizing things?",
      options: ["1", "2", "3", "4", "5"],
    ),
    Question(questionText: "Do you enjoy talking to people?", options: ["1", "2", "3", "4", "5"]),
    Question(
      questionText: "Do you like making or preparing things?",
      options: ["1", "2", "3", "4", "5"],
    ),
    Question(
      questionText: "Can you follow simple instructions?",
      options: ["Yes", "Sometimes", "Needs help"],
    ),
    Question(
      questionText: "Can You remember daily routines?",
      options: ["Yes", "Sometimes", "Needs help"],
    ),
    Question(
      questionText: "Can you work well with others?",
      options: ["Yes", "Sometimes", "Needs help"],
    ),
    Question(
      questionText: "Can you stay focused on a task until it is finished?",
      options: ["Yes", "Short time", "Needs reminders"],
    ),
    Question(
      questionText: "Do you like working in a group?",
      options: ["Yes", "Sometimes", "Prefer alone"],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _completionAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _completionAnimationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _completionAnimationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _completionAnimationController.dispose();
    super.dispose();
  }

  void selectAnswer(String answer) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = answer;
    });

    // Navigate to next question after a short delay
    Future.delayed(Duration(milliseconds: 300), () {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
        });
      } else {
        // All questions answered, show completion or navigate back
        _showCompletionDialog();
      }
    });
  }

  List<int> _calculateScores() {
    List<int> scores = [];
    
    for (int i = 0; i < selectedAnswers.length; i++) {
      String answer = selectedAnswers[i];
      
      // Convert answers to numeric scores
      if (answer == "1" || answer == "2" || answer == "3" || answer == "4" || answer == "5") {
        scores.add(int.parse(answer));
      } else if (answer == "Yes") {
        scores.add(5);
      } else if (answer == "Sometimes") {
        scores.add(3);
      } else if (answer == "Needs help") {
        scores.add(1);
      } else {
        scores.add(0); // Default for unanswered
      }
    }
    
    return scores;
  }

  void _showCompletionDialog() {
    _completionAnimationController.forward();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AnimatedBuilder(
          animation: _completionAnimationController,
          builder: (context, child) {
            return ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Dialog(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFB322E0),
                          Color(0xFF9b1bcc),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFB322E0).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Checkmark
                        SizedBox(
                          height: 120,
                          width: 120,
                          child: _buildAnimatedCheckmark(),
                        ),
                        SizedBox(height: 30),
                        Text(
                          "Quiz Completed!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 15),
                        Text(
                          "Thank you for completing the questionnaire.",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                // Calculate scores from questionnaire
                                List<int> scores = _calculateScores();
                                
                                // Get model prediction with scores
                                var result = await VocationalModelService.instance.predictModuleWithScores(scores);
                                String predictedModule = result['predictedModule'];
                                double confidence = result['confidence'];
                                Map<String, double> allScores = result['allScores'];
                                
                                print('Predicted module: $predictedModule');
                                print('Confidence: ${(confidence * 100).toStringAsFixed(1)}%');
                                print('All scores: $allScores');
                                
                                // Show results dialog
                                _showResultsDialog(context, predictedModule, confidence, allScores);
                              } catch (e) {
                                print('Error predicting module: $e');
                                // Fallback to regular navigation if model fails
                                _completionAnimationController.reverse().then((_) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (context) => GameMenuNew()),
                                  );
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              "Continue",
                              style: TextStyle(
                                color: Color(0xFFB322E0),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
          },
        );
      },
    ).then((_) {
      _completionAnimationController.reset();
    });
  }

  Widget _buildAnimatedCheckmark() {
    return CustomPaint(
      painter: AnimatedCheckmarkPainter(
        progress: _completionAnimationController.value,
      ),
    );
  }

  void goToPreviousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB322E0), Color(0xFF9b1bcc)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Top Navigation Bar
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () {
                        if (currentQuestionIndex > 0) {
                          goToPreviousQuestion();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    Expanded(
                      child: Container(
                        height: 8,
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      "${currentQuestionIndex + 1}/${questions.length}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                // Quiz Header with Stars
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Left Star
                    Positioned(
                      left: 0,
                      child: Text("✦", style: TextStyle(color: Color(0xFFFFD700), fontSize: 24)),
                    ),
                    // QUIZ Header
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        "QUIZ",
                        style: TextStyle(
                          color: Color(0xFFB322E0),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    // Right Stars
                    Positioned(
                      right: 10,
                      top: -5,
                      child: Text("✦", style: TextStyle(color: Color(0xFFFFD700), fontSize: 20)),
                    ),
                    Positioned(
                      right: -15,
                      bottom: -5,
                      child: Text("✦", style: TextStyle(color: Color(0xFFFFD700), fontSize: 20)),
                    ),
                    // Question Mark
                    Positioned(
                      right: 20,
                      top: 0,
                      child: Text("?", style: TextStyle(color: Colors.white, fontSize: 24)),
                    ),
                  ],
                ),
                SizedBox(height: 50),
                // Question Text (optional - not in template but helpful)
                Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentQuestion.questionText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                // Options Grid
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _buildOptionsGrid(currentQuestion),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({required String label, required String text, required String answer}) {
    final isSelected = selectedAnswers[currentQuestionIndex] == answer;

    return GestureDetector(
      onTap: () => selectAnswer(answer),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Text(
                  "$label: $text",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFB322E0),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              left: -8,
              top: -8,
              child: Text("✦", style: TextStyle(color: Color(0xFFFFD700), fontSize: 20)),
            ),
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFB322E0).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsGrid(Question question) {
    final optionCount = question.options.length;

    // For 5 options (1-5 rating)
    if (optionCount == 5) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildOptionButton(
                          label: "A",
                          text: question.options[0],
                          answer: question.options[0],
                        ),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: _buildOptionButton(
                          label: "B",
                          text: question.options[1],
                          answer: question.options[1],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildOptionButton(
                          label: "C",
                          text: question.options[2],
                          answer: question.options[2],
                        ),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: _buildOptionButton(
                          label: "D",
                          text: question.options[3],
                          answer: question.options[3],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: _buildOptionButton(
              label: "E",
              text: question.options[4],
              answer: question.options[4],
            ),
          ),
        ],
      );
    }
    // For 3 options
    else {
      return Column(
        children: List.generate(optionCount, (index) {
          final letters = ['A', 'B', 'C'];
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: _buildOptionButton(
                label: letters[index],
                text: question.options[index],
                answer: question.options[index],
              ),
            ),
          );
        }),
      );
    }
  }

  void _resetQuestionnaire() {
    setState(() {
      currentQuestionIndex = 0;
      selectedAnswers = List.filled(9, '');
    });
    _completionAnimationController.reset();
  }

  void _showResultsDialog(BuildContext context, String predictedModule, double confidence, Map<String, double> allScores) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🎯 Assessment Results',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB322E0),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  'Recommended Path: ${predictedModule.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  'All Module Scores:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                ...allScores.entries.map((entry) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${(entry.value * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: entry.key == predictedModule ? Color(0xFFB322E0) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        print('Retake Test button pressed');
                        Navigator.of(context).pop();
                        _resetQuestionnaire();
                        print('Questionnaire reset completed');
                      },
                      child: Text(
                        'Retake Test',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        print('Continue button pressed');
                        print('Navigating to GameMenuNew with module: $predictedModule');
                        Navigator.of(context).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => GameMenuNew(predictedModule: predictedModule)),
                        );
                        print('Navigation to GameMenuNew completed');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFB322E0),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimatedCheckmarkPainter extends CustomPainter {
  final double progress;

  AnimatedCheckmarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw circle background
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      circlePaint,
    );

    // Draw circle border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final circlePath = Path();
    circlePath.addArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2 - 5,
      ),
      -90 * 3.14159 / 180,
      progress * 2 * 3.14159,
    );

    canvas.drawPath(circlePath, borderPaint);

    // Draw checkmark
    if (progress > 0.3) {
      final checkmarkProgress = (progress - 0.3) / 0.7;
      final path = Path();

      // Left part of checkmark
      final startX = size.width * 0.35;
      final startY = size.height * 0.55;
      final midX = size.width * 0.45;
      final midY = size.height * 0.65;

      path.moveTo(startX, startY);
      path.lineTo(
        startX + (midX - startX) * checkmarkProgress,
        startY + (midY - startY) * checkmarkProgress,
      );

      canvas.drawPath(path, paint);

      // Right part of checkmark
      if (checkmarkProgress > 0.5) {
        final rightProgress = (checkmarkProgress - 0.5) / 0.5;
        final path2 = Path();

        final endX = size.width * 0.65;
        final endY = size.height * 0.35;

        path2.moveTo(midX, midY);
        path2.lineTo(
          midX + (endX - midX) * rightProgress,
          midY + (endY - midY) * rightProgress,
        );

        canvas.drawPath(path2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(AnimatedCheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
