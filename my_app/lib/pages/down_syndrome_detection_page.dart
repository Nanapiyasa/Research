import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'flip_card_game_widget.dart';

class DownSyndromeDetectionPage extends StatefulWidget {
  final String apiUrl = "http://10.0.2.2:5000"; // For emulator
  // final String apiUrl = "http://192.168.1.100:5000"; // For physical device

  @override
  _DownSyndromeDetectionPageState createState() => _DownSyndromeDetectionPageState();
}

class _DownSyndromeDetectionPageState extends State<DownSyndromeDetectionPage> {
  // Connection status
  bool _isConnected = false;
  bool _isConnecting = false;
  String _errorMessage = '';

  // Sensor data
  Timer? _statusTimer;
  int _currentHeartRate = 0;
  List<Map<String, dynamic>> _heartRateHistory = [];
  Map<String, dynamic>? _prediction;
  
  // User profile
  Map<String, dynamic> _userProfile = {
    'Age': 8,
    'Weight': 12,
    'Height': 52,
    'Memory_Score': 20,
    'Reaction_Time': 100
  };

  // Game scores
  int _flipCardScore = 20;
  int _reactionTime = 100;
  
  // UI state
  bool _showGame = false;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _disconnect();
    super.dispose();
  }

  Future<void> _checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.apiUrl}/health'),
      ).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Health: $data');
        
        setState(() {
          _isConnected = data['connected'] ?? false;
        });
        
        if (_isConnected) {
          _startStatusPolling();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Cannot connect to API server';
      });
    }
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.apiUrl}/connect'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });

        _startStatusPolling();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to sensor'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Connection failed');
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Failed to connect: $e';
      });
    }
  }

  Future<void> _disconnect() async {
    try {
      await http.post(
        Uri.parse('${widget.apiUrl}/disconnect'),
      );
    } catch (e) {
      print('Disconnect error: $e');
    }

    _statusTimer?.cancel();
    setState(() {
      _isConnected = false;
      _prediction = null;
      _heartRateHistory.clear();
    });
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!_isConnected) return;

      try {
        final response = await http.get(
          Uri.parse('${widget.apiUrl}/status'),
        ).timeout(Duration(seconds: 2));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          setState(() {
            _currentHeartRate = data['heart_rate'] ?? 0;
            _heartRateHistory = List<Map<String, dynamic>>.from(data['history'] ?? []);
            
            // Check if prediction is available
            if (data['prediction'] != null) {
              _prediction = data['prediction'];
            }
          });
        }
      } catch (e) {
        print('Status error: $e');
      }
    });
  }

  Future<void> _updateUserProfile() async {
    try {
      final response = await http.post(
        Uri.parse('${widget.apiUrl}/user-profile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(_userProfile),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submitGameScore(int memoryScore, int reactionTime) async {
    setState(() {
      _flipCardScore = memoryScore;
      _reactionTime = reactionTime;
      _userProfile['Memory_Score'] = memoryScore;
      _userProfile['Reaction_Time'] = reactionTime;
      _showGame = false;
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.apiUrl}/game-score'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'memory_score': memoryScore,
          'reaction_time': reactionTime,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game score submitted: Memory=$memoryScore, Reaction=$reactionTime ms'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Update user profile after game
        await _updateUserProfile();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit score'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _resetPrediction() async {
    try {
      final response = await http.post(
        Uri.parse('${widget.apiUrl}/reset-prediction'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _prediction = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prediction reset'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reset'), backgroundColor: Colors.red),
      );
    }
  }

  void _showUserProfileDialog() {
    final ageController = TextEditingController(text: _userProfile['Age'].toString());
    final weightController = TextEditingController(text: _userProfile['Weight'].toString());
    final heightController = TextEditingController(text: _userProfile['Height'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('User Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ageController,
                  decoration: InputDecoration(labelText: 'Age (years)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(labelText: 'Weight (kg)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: heightController,
                  decoration: InputDecoration(labelText: 'Height (cm)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _userProfile['Age'] = int.tryParse(ageController.text) ?? 8;
                  _userProfile['Weight'] = int.tryParse(weightController.text) ?? 12;
                  _userProfile['Height'] = int.tryParse(heightController.text) ?? 52;
                });
                _updateUserProfile();
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showGame ? 'Memory Game' : 'Down Syndrome Detection'),
        backgroundColor: _showGame ? Colors.orange.shade900 : Colors.purple.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_showGame) ...[
            IconButton(
              icon: Icon(Icons.person),
              onPressed: _showUserProfileDialog,
            ),
            IconButton(
              icon: Icon(Icons.sports_esports),
              onPressed: () {
                setState(() {
                  _showGame = true;
                });
              },
            ),
          ] else
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _showGame = false;
                });
              },
            ),
        ],
      ),
      body: _showGame 
          ? FlipCardGameWidget(
              onGameComplete: (memoryScore, reactionTime) {
                _submitGameScore(memoryScore, reactionTime);
              },
            )
          : _buildMainScreen(),
    );
  }

  Widget _buildMainScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.purple.shade900, Colors.purple.shade700],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Status Bar - Fixed at top
            _buildStatusBar(),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    // Heart Rate Display
                    _buildHeartRateDisplay(),

                    // Heart Rate History
                    if (_heartRateHistory.isNotEmpty) 
                      _buildHeartRateHistory(),

                    // Prediction Result
                    if (_prediction != null) 
                      _buildPredictionResult(),

                    // User Profile Info
                    _buildUserProfile(),

                    // Game Scores
                    _buildGameScores(),

                    // Control Buttons
                    _buildControlButtons(),

                    // Error Message
                    if (_errorMessage.isNotEmpty) 
                      _buildErrorMessage(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black26,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              _isConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isConnected) ...[
            SizedBox(width: 16),
            Icon(Icons.favorite, color: Colors.red, size: 16),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                '$_currentHeartRate BPM',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_prediction != null) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Level: ${_prediction!['level']}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHeartRateDisplay() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current Heart Rate',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$_currentHeartRate',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              SizedBox(width: 5),
              Text(
                'BPM',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (_heartRateHistory.isNotEmpty) ...[
            SizedBox(height: 10),
            Text(
              'Monitoring for stable reading...',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeartRateHistory() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _heartRateHistory.length,
        itemBuilder: (context, index) {
          final item = _heartRateHistory[index];
          return Container(
            width: 50,
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item['value']}',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  'BPM',
                  style: TextStyle(color: Colors.white70, fontSize: 8),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPredictionResult() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.green.shade700),
              SizedBox(width: 8),
              Text(
                'Prediction Result',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Down Syndrome Level', style: TextStyle(color: Colors.grey.shade600)),
                    Text(
                      _prediction!['level'] ?? 'Unknown',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Heart Rate', style: TextStyle(color: Colors.grey.shade600)),
                  Text(
                    '${_prediction!['heart_rate']} BPM',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Text('Recommendation:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(_prediction!['recommendation'] ?? 'No recommendation available'),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _resetPrediction,
                icon: Icon(Icons.refresh),
                label: Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildProfileItem('Age', '${_userProfile['Age']} yrs', Icons.calendar_today),
          _buildProfileItem('Weight', '${_userProfile['Weight']} kg', Icons.monitor_weight),
          _buildProfileItem('Height', '${_userProfile['Height']} cm', Icons.height),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildGameScores() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showGame = true;
        });
      },
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.orange.shade800),
                SizedBox(width: 8),
                Text(
                  'Game Scores',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                Spacer(),
                Icon(Icons.play_arrow, color: Colors.orange.shade800),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Memory Score', style: TextStyle(color: Colors.grey.shade600)),
                      Text(
                        '$_flipCardScore',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Reaction Time', style: TextStyle(color: Colors.grey.shade600)),
                      Text(
                        '$_reactionTime ms',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Row(
        children: [
          if (!_isConnected)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isConnecting ? null : _connect,
                icon: Icon(Icons.sensors),
                label: Text(_isConnecting ? 'Connecting...' : 'Start Monitoring'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          else
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _disconnect,
                icon: Icon(Icons.sensors_off),
                label: Text('Stop Monitoring'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.red.shade900),
            ),
          ),
        ],
      ),
    );
  }
}