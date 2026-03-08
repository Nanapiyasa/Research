import 'package:flutter/material.dart';
import 'game_menu_new.dart';
import 'model_service.dart';

// Question model
class Question {
  final String questionText;
  final List<String> options;
  final bool isStarRating;

  Question({required this.questionText, required this.options, this.isStarRating = false});
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
    Question(questionText: "Does the student enjoy helping others?", options: ["1", "2", "3", "4", "5"], isStarRating: true),
    Question(
      questionText: "Does the student like arranging or organizing things?",
      options: ["1", "2", "3", "4", "5"],
      isStarRating: true,
    ),
    Question(questionText: "Does the student enjoy interacting with people?", options: ["1", "2", "3", "4", "5"], isStarRating: true),
    Question(
      questionText: "Does the student like making or preparing things?",
      options: ["1", "2", "3", "4", "5"],
      isStarRating: true,
    ),
    Question(
      questionText: "Can the student follow simple instructions?",
      options: ["Yes", "Sometimes", "Needs help"],
    ),
    Question(
      questionText: "Can the student remember daily routines?",
      options: ["Yes", "Sometimes", "Needs help"],
    ),
    Question(
      questionText: "Can the student work well with others?",
      options: ["Yes", "Sometimes", "Needs help"],
    ),
    Question(
      questionText: "Can the student stay focused on a task until it is finished?",
      options: ["Yes", "Short time", "Needs reminders"],
    ),
    Question(
      questionText: "Does the student like working in a group?",
      options: ["Yes", "Sometimes", "Prefer alone"],
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize completion animation
    _completionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _completionAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _completionAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Show instruction dialog after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionDialog();
    });
  }

  @override
  void dispose() {
    _completionAnimationController.dispose();
    super.dispose();
  }

  void _showInstructionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
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
                // Icon instead of checkmark
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Icon(
                    Icons.assignment,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
                // SizedBox(height: 30),
                // Text(
                //   "Assessment",
                //   style: TextStyle(
                //     color: Colors.white,
                //     fontWeight: FontWeight.bold,
                //     fontSize: 28,
                //     letterSpacing: 1,
                //   ),
                //   textAlign: TextAlign.center,
                // ),
                SizedBox(height: 8),
                Text(
                  "Caregiver Assessment",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15),
                Text(
                  "This questionnaire helps us understand the student's abilities and preferences. Please answer honestly about the student you care for.",
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
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
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
        );
      },
    );
  }

  void selectAnswer(String answer) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = answer;
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
                        SizedBox(height: 8),
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
                                // Calculate fallback scores
                                List<int> scores = _calculateScores();
                                var fallbackResult = await VocationalModelService.instance.predictModuleWithScores(scores);
                                
                                // Fallback to regular navigation if model fails
                                _completionAnimationController.reverse().then((_) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (context) => GameMenuNew(
                                      questionnaireResults: fallbackResult,
                                      predictedModule: fallbackResult['predictedModule'],
                                    )),
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

  void goToNextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      // Show completion dialog when on last question
      _showCompletionDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Progress Bar
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFFD700),
                                Color(0xFFFFA500),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Question Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Question ${currentQuestionIndex + 1}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFFFD700).withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                "For caregiver",
                                style: TextStyle(
                                  color: Color(0xFF2D3748),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${currentQuestionIndex + 1}/${questions.length}",
                            style: TextStyle(
                              color: Color(0xFF667EEA),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Question Card
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Text
                        Text(
                          currentQuestion.questionText,
                          style: TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 32),
                        
                        // Options
                        Expanded(
                          child: Scrollbar(
                            thumbVisibility: true,
                            thickness: 6,
                            radius: Radius.circular(3),
                            child: SingleChildScrollView(
                              child: _buildModernOptionsGrid(currentQuestion),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Navigation Bar
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Previous Button
                    Expanded(
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFE53E3E),
                              Color(0xFFC53030),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFE53E3E).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: currentQuestionIndex > 0 ? goToPreviousQuestion : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back, size: 18),
                              SizedBox(width: 8),
                              Text("Previous"),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Next Button
                    Expanded(
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF38A169),
                              Color(0xFF2F855A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF38A169).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: selectedAnswers[currentQuestionIndex].isNotEmpty 
                              ? goToNextQuestion 
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Next"),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernOptionsGrid(Question question) {
    final optionCount = question.options.length;

    // For star rating questions (questions 1-4)
    if (question.isStarRating) {
      return Column(
        children: [
          SizedBox(height: 20),
          Text(
            "Rate your interest level:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => selectAnswer((index + 1).toString()),
                child: Column(
                  children: [
                    Icon(
                      (int.tryParse(selectedAnswers[currentQuestionIndex] ?? "0") ?? 0) > index 
                          ? Icons.star 
                          : Icons.star_border,
                      size: 40,
                      color: Colors.amber,
                    ),
                    SizedBox(height: 5),
                    Text(
                      (index + 1).toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          SizedBox(height: 10),
          Text(
            selectedAnswers[currentQuestionIndex].isEmpty 
                ? "Tap a star to rate"
                : "You rated: ${selectedAnswers[currentQuestionIndex]} star${selectedAnswers[currentQuestionIndex] == "1" ? "" : "s"}",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    // For 5 options (1-5 rating) - non-star questions
    if (optionCount == 5) {
      return Column(
        children: [
          _buildModernOptionButton(
            label: "A",
            text: question.options[0],
            answer: question.options[0],
          ),
          SizedBox(height: 12),
          _buildModernOptionButton(
            label: "B",
            text: question.options[1],
            answer: question.options[1],
          ),
          SizedBox(height: 12),
          _buildModernOptionButton(
            label: "C",
            text: question.options[2],
            answer: question.options[2],
          ),
          SizedBox(height: 12),
          _buildModernOptionButton(
            label: "D",
            text: question.options[3],
            answer: question.options[3],
          ),
          SizedBox(height: 12),
          _buildModernOptionButton(
            label: "E",
            text: question.options[4],
            answer: question.options[4],
          ),
        ],
      );
    }
    // For 3 options
    else {
      return Column(
        children: List.generate(optionCount, (index) {
          final letters = ['A', 'B', 'C'];
          return Padding(
            padding: EdgeInsets.only(bottom: index < optionCount - 1 ? 12 : 0),
            child: _buildModernOptionButton(
              label: letters[index],
              text: question.options[index],
              answer: question.options[index],
            ),
          );
        }),
      );
    }
  }

  Widget _buildModernOptionButton({required String label, required String text, required String answer}) {
    final isSelected = selectedAnswers[currentQuestionIndex] == answer;

    return GestureDetector(
      onTap: () => selectAnswer(answer),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF667EEA).withValues(alpha: 0.1) : Color(0xFFF8F9FA),
          border: Border.all(
            color: isSelected ? Color(0xFF667EEA) : Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Option Letter
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF667EEA) : Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Color(0xFF64748B),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            // Option Text
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isSelected ? Color(0xFF667EEA) : Color(0xFF2D3748),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            // Check Icon for Selected
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Color(0xFF667EEA),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _resetQuestionnaire() {
    setState(() {
      currentQuestionIndex = 0;
      selectedAnswers = List.filled(9, '');
    });
    _completionAnimationController.reset();
  }

  void _showResultsDialog(BuildContext context, String predictedModule, double confidence, Map<String, double> allScores) {
    // Create the complete results map
    Map<String, dynamic> completeResults = {
      'predictedModule': predictedModule,
      'confidence': confidence,
      'allScores': allScores,
    };
    
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
                SizedBox(height: 8),
                Text(
                  'Recommended Path: ${predictedModule.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'All Module Scores:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
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
                        print('Complete results: $completeResults');
                        Navigator.of(context).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => GameMenuNew(
                            questionnaireResults: completeResults,
                            predictedModule: predictedModule,
                          )),
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
