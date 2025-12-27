import 'package:flutter/material.dart';

// Question model
class Question {
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String optionE;

  Question({
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.optionE,

  });
}

// Questionnaire Screen
class QuestionnaireScreen extends StatefulWidget {
  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int currentQuestionIndex = 0;
  List<String> selectedAnswers = List.filled(6, '');

  final List<Question> questions = [
    Question(
      questionText: "What is your primary interest in job simulation?",
      optionA: "Customer Service",
      optionB: "Technical Skills",
      optionC: "Leadership Roles",
      optionD: "Creative Work",
    ),
    Question(
      questionText: "Comfort with communication",
      optionA: "1",
      optionB: "2",
      optionC: "3",
      optionD: "4",
      optionE: "5",
    ),
    Question(
      questionText: "What type of work environment do you prefer?",
      optionA: "Fast-paced",
      optionB: "Structured",
      optionC: "Collaborative",
      optionD: "Independent",
    ),
    Question(
      questionText: "Which skill would you like to develop most?",
      optionA: "Communication",
      optionB: "Problem Solving",
      optionC: "Time Management",
      optionD: "Teamwork",
    ),
    Question(
      questionText: "How comfortable are you with using technology?",
      optionA: "Very Comfortable",
      optionB: "Somewhat Comfortable",
      optionC: "Learning",
      optionD: "Prefer Traditional Methods",
    ),
    Question(
      questionText: "What motivates you most in a job?",
      optionA: "Helping Others",
      optionB: "Personal Growth",
      optionC: "Recognition",
      optionD: "Stable Income",
    ),
  ];

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

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFB322E0),
          title: Text(
            "Quiz Completed!",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Thank you for completing the questionnaire.",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to module selection
              },
              child: Text(
                "OK",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
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
            colors: [
              Color(0xFFB322E0),
              Color(0xFF9b1bcc),
            ],
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
                          color: Colors.white.withOpacity(0.3),
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
                      child: Text(
                        "✦",
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 24,
                        ),
                      ),
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
                      child: Text(
                        "✦",
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -15,
                      bottom: -5,
                      child: Text(
                        "✦",
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 20,
                        ),
                      ),
                    ),
                    // Question Mark
                    Positioned(
                      right: 20,
                      top: 0,
                      child: Text(
                        "?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 50),
                // Question Text (optional - not in template but helpful)
                Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
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
                // Options Grid (2x2)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
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
                                        text: currentQuestion.optionA,
                                        answer: "A",
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Expanded(
                                      child: _buildOptionButton(
                                        label: "B",
                                        text: currentQuestion.optionB,
                                        answer: "B",
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
                                        text: currentQuestion.optionC,
                                        answer: "C",
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Expanded(
                                      child: _buildOptionButton(
                                        label: "D",
                                        text: currentQuestion.optionD,
                                        answer: "D",
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
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
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
              child: Text(
                "✦",
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 20,
                ),
              ),
            ),
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFB322E0).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


