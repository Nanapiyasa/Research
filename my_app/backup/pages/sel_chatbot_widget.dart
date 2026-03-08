// lib/pages/sel_chatbot_widget.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'sel_game_model.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class SELChatbotWidget extends StatefulWidget {
  final String apiUrl;
  final String userLevel;
  final SELGameStats userStats;

  const SELChatbotWidget({
    Key? key,
    required this.apiUrl,
    required this.userLevel,
    required this.userStats,
  }) : super(key: key);

  @override
  _SELChatbotWidgetState createState() => _SELChatbotWidgetState();
}

class _SELChatbotWidgetState extends State<SELChatbotWidget> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  // Suggested questions based on user level
  List<String> get _suggestedQuestions {
    switch (widget.userLevel.toLowerCase()) {
      case 'beginner':
        return [
          'How can I understand my feelings better?',
          'What should I do when I feel angry?',
          'How do I make friends?',
        ];
      case 'intermediate':
        return [
          'How can I help a sad friend?',
          'What if someone is mean to me?',
          'How do I stay calm during tests?',
        ];
      case 'advanced':
        return [
          'How to resolve conflicts peacefully?',
          'Ways to show empathy to others?',
          'How to build lasting friendships?',
        ];
      default:
        return [
          'How are you feeling today?',
          'Can you help me with emotions?',
          'Tell me about SEL skills',
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _checkApiHealth();
    _sendWelcomeMessage();
  }

  Future<void> _checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.apiUrl}/health'),
      ).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        print('API is healthy');
      } else {
        print('API health check failed');
        _addMessage(ChatMessage(
          text: 'Note: I\'m running in offline mode with basic responses.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      print('API not reachable: $e');
      _addMessage(ChatMessage(
        text: 'I\'m running in offline mode. I can still help with basic questions!',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  void _sendWelcomeMessage() {
    String welcomeMessage =
        'Hello! I\'m your SEL guide. Based on your game results, '
        'you\'re at a ${widget.userLevel} level. '
        'How can I help you with social-emotional learning today?';

    _addMessage(ChatMessage(
      text: welcomeMessage,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });

    // Scroll to bottom
    Timer(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Fallback responses when API is not available
  String _getFallbackResponse(String message) {
    message = message.toLowerCase();

    if (message.contains('angry') || message.contains('mad')) {
      return "When you feel angry, try taking deep breaths or counting to 10. Would you like to learn more calming techniques?";
    } else if (message.contains('sad')) {
      return "It's okay to feel sad. Talking to someone you trust can help. What's making you feel sad?";
    } else if (message.contains('friend')) {
      return "Making friends takes practice! Try smiling and saying hello to someone new. Would you like some tips?";
    } else if (message.contains('scared') || message.contains('fear')) {
      return "Feeling scared is normal. Remember that you're brave and can face your fears one step at a time.";
    } else if (message.contains('happy')) {
      return "That's wonderful! Sharing your happiness with others can make everyone's day better.";
    } else if (message.contains('help')) {
      return "I'm here to help you understand your feelings and build social skills. What would you like to work on?";
    } else {
      return "That's interesting! Tell me more about how you're feeling.";
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    // Add user message
    _addMessage(ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    setState(() {
      _isTyping = true;
    });

    try {
      // Get only the data we need for the API
      final predictionData = widget.userStats.toPredictionData();

      print('Sending to API: $predictionData'); // Debug print

      // Send to chatbot API
      final response = await http.post(
        Uri.parse('${widget.apiUrl}/chatbot-response'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': userMessage,
          'user_level': widget.userLevel,
          'user_stats': predictionData, // Use predictionData instead of full toJson
        }),
      ).timeout(Duration(seconds: 5));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Add bot response
        _addMessage(ChatMessage(
          text: data['response'] ?? 'I understand. Can you tell me more?',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      } else {
        // Use fallback response
        _addMessage(ChatMessage(
          text: _getFallbackResponse(userMessage),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      print('Error sending message: $e');
      // Use fallback response
      _addMessage(ChatMessage(
        text: _getFallbackResponse(userMessage),
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Chat header
          _buildChatHeader(),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Typing indicator
          if (_isTyping)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingDot(0),
                        _buildTypingDot(150),
                        _buildTypingDot(300),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Suggested questions (only show at beginning)
          if (_messages.length < 3)
            Container(
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestedQuestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(_suggestedQuestions[index]),
                      onPressed: () {
                        _messageController.text = _suggestedQuestions[index];
                        _sendMessage();
                      },
                      backgroundColor: Colors.purple.shade100,
                    ),
                  );
                },
              ),
            ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade900,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.chat, color: Colors.purple.shade900),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEL Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Level: ${widget.userLevel}',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Online',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.purple.shade100,
              child: Icon(Icons.android, color: Colors.purple.shade900, size: 16),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.purple : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isUser ? Radius.circular(20) : Radius.circular(4),
                  bottomRight: message.isUser ? Radius.circular(4) : Radius.circular(20),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.purple,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 500),
      child: Container(
        width: 8,
        height: 8,
        margin: EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade600,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _sendMessage,
            mini: true,
            backgroundColor: Colors.purple,
            child: Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}