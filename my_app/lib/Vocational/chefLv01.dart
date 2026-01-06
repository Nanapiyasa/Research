import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class KitchenLearningGame extends StatefulWidget {
  const KitchenLearningGame({super.key});

  @override
  State<KitchenLearningGame> createState() => _KitchenLearningGameState();
}

class KitchenItem {
  final int id;
  final String name;
  final String imageUrl;
  final Color primaryColor;
  final Color accentColor;

  KitchenItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.primaryColor,
    required this.accentColor,
  });
}

class _KitchenLearningGameState extends State<KitchenLearningGame>
    with TickerProviderStateMixin {
  late FlutterTts flutterTts;

  final List<KitchenItem> kitchenItems = [
    KitchenItem(
      id: 1,
      name: 'Spoon',
      imageUrl: 'https://images.unsplash.com/photo-1589804430678-d4a4a8b933be?w=400&h=400&fit=crop',
      primaryColor: const Color(0xFF6366F1),
      accentColor: const Color(0xFF818CF8),
    ),
    KitchenItem(
      id: 2,
      name: 'Fork',
      imageUrl: 'https://images.unsplash.com/photo-1606107260586-61c991b06b0a?w=400&h=400&fit=crop',
      primaryColor: const Color(0xFF10B981),
      accentColor: const Color(0xFF34D399),
    ),
    KitchenItem(
      id: 3,
      name: 'Plate',
      imageUrl: 'https://images.unsplash.com/photo-1578469550956-0e16b69c6a3d?w=400&h=400&fit=crop',
      primaryColor: const Color(0xFFF59E0B),
      accentColor: const Color(0xFFFBBF24),
    ),
    KitchenItem(
      id: 4,
      name: 'Cup',
      imageUrl: 'https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?w=400&h=400&fit=crop',
      primaryColor: const Color(0xFFEC4899),
      accentColor: const Color(0xFFF472B6),
    ),
    KitchenItem(
      id: 5,
      name: 'Knife',
      imageUrl: 'https://images.unsplash.com/photo-1593618998160-e34014e67546?w=400&h=400&fit=crop',
      primaryColor: const Color(0xFF8B5CF6),
      accentColor: const Color(0xFFA78BFA),
    ),
    KitchenItem(
      id: 6,
      name: 'Bowl',
      imageUrl: 'https://images.unsplash.com/photo-1585338107529-13adb4d5c6e5?w=400&h=400&fit=crop',
      primaryColor: const Color(0xFFEF4444),
      accentColor: const Color(0xFFF87171),
    ),
  ];

  String page = 'introduction';
  KitchenItem? currentTarget;
  List<KitchenItem> options = [];
  int score = 0;
  List<int> completedItems = [];
  bool showCelebration = false;
  bool wrongAttempt = false;
  int? selectedItemId;

  late ConfettiController confettiController;
  late AnimationController shakeController;
  late Animation<double> shakeAnimation;
  late AnimationController pulseController;
  late Animation<double> pulseAnimation;
  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _initTts();

    confettiController = ConfettiController(duration: const Duration(seconds: 4));

    shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: shakeController, curve: Curves.elasticOut),
    );

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );
    pulseController.repeat(reverse: true);

    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: fadeController, curve: Curves.easeOut),
    );

    startNewRound();
  }

  Future<void> _initTts() async {
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.2);
    await flutterTts.setSpeechRate(0.5);
    List<dynamic> voices = await flutterTts.getVoices;
    for (var voice in voices) {
      if (voice['locale'].toString().startsWith('en') &&
          voice['name'].toString().toLowerCase().contains('female')) {
        await flutterTts.setVoice(voice);
        break;
      }
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    confettiController.dispose();
    shakeController.dispose();
    pulseController.dispose();
    fadeController.dispose();
    super.dispose();
  }

  void startNewRound() {
    final remaining = kitchenItems.where((item) => !completedItems.contains(item.id)).toList();
    if (remaining.isEmpty) return;

    final random = Random();
    final target = remaining[random.nextInt(remaining.length)];

    final wrongOptions = kitchenItems.where((item) => item.id != target.id).toList()
      ..shuffle(random);
    final selectedWrong = wrongOptions.take(3).toList();

    final allOptions = [target, ...selectedWrong]..shuffle(random);

    setState(() {
      currentTarget = target;
      options = allOptions;
      page = 'introduction';
      wrongAttempt = false;
      selectedItemId = null;
    });
    
    fadeController.forward(from: 0);
  }

  Future<void> speak(String text, {bool slower = false}) async {
    await flutterTts.stop();
    await flutterTts.setSpeechRate(slower ? 0.45 : 0.5);
    await flutterTts.speak(text);
  }

  void handleItemSelection(KitchenItem selectedItem) {
    setState(() => selectedItemId = selectedItem.id);

    if (selectedItem.id == currentTarget!.id) {
      handleCorrect();
    } else {
      handleWrong();
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => selectedItemId = null);
    });
  }

  void handleCorrect() {
    setState(() {
      score++;
      showCelebration = true;
      completedItems.add(currentTarget!.id);
    });
    confettiController.play();
    speak('Excellent! You found the ${currentTarget!.name}! Well done!');

    Future.delayed(const Duration(seconds: 3), () {
      confettiController.stop();
      setState(() => showCelebration = false);
      if (completedItems.length == kitchenItems.length) {
        speak('Wonderful! You\'ve learned all the kitchen items!', slower: true);
      } else {
        startNewRound();
      }
    });
  }

  void handleWrong() {
    setState(() => wrongAttempt = true);
    shakeController.forward().then((_) => shakeController.reset());
    speak('Not quite. Try again!');
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => wrongAttempt = false);
    });
  }

  void resetGame() {
    setState(() {
      completedItems = [];
      score = 0;
      showCelebration = false;
      selectedItemId = null;
    });
    startNewRound();
  }

  bool get allCompleted => completedItems.length == kitchenItems.length;

  @override
  Widget build(BuildContext context) {
    final isIntroduction = page == 'introduction' && currentTarget != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isIntroduction),
            Expanded(
              child: Stack(
                children: [
                  FadeTransition(
                    opacity: fadeAnimation,
                    child: isIntroduction ? _buildIntroductionPage() : _buildGamePage(),
                  ),
                  if (showCelebration)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.15),
                        child: Center(
                          child: ConfettiWidget(
                            confettiController: confettiController,
                            blastDirectionality: BlastDirectionality.explosive,
                            emissionFrequency: 0.02,
                            numberOfParticles: 60,
                            gravity: 0.25,
                            colors: const [
                              Color(0xFF6366F1),
                              Color(0xFF10B981),
                              Color(0xFFF59E0B),
                              Color(0xFFEC4899),
                              Color(0xFF8B5CF6),
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
    );
  }

  Widget _buildHeader(bool isIntroduction) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.arrow_back_rounded, size: 24, color: Color(0xFF64748B)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIntroduction ? 'Learning Mode' : 'Practice Time',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Kitchen Items',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$score/${kitchenItems.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (!isIntroduction) ...[
            const SizedBox(width: 12),
            Material(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: resetGame,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.refresh_rounded, size: 24, color: Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntroductionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Let\'s learn this item',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: pulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [currentTarget!.primaryColor, currentTarget!.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: currentTarget!.primaryColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  currentTarget!.name,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: currentTarget!.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.volume_up_rounded,
                label: 'Listen',
                color: const Color(0xFF6366F1),
                onPressed: () => speak("This is a ${currentTarget!.name}. Can you say ${currentTarget!.name}?", slower: true),
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.play_arrow_rounded,
                label: 'Start Practice',
                color: const Color(0xFF10B981),
                isPrimary: true,
                onPressed: () {
                  setState(() => page = 'game');
                  fadeController.forward(from: 0);
                  Timer(const Duration(milliseconds: 500), () {
                    speak("Now find the ${currentTarget!.name}!", slower: true);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary ? color : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isPrimary ? 28 : 24,
            vertical: 16,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : color,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamePage() {
    return Column(
      children: [
        if (showCelebration)
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  'Excellent!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        if (allCompleted)
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Column(
              children: [
                Icon(Icons.emoji_events_rounded, color: Colors.white, size: 48),
                SizedBox(height: 16),
                Text(
                  'All Complete!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'You\'ve mastered all kitchen items',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (!allCompleted && currentTarget != null)
          AnimatedBuilder(
            animation: shakeAnimation,
            builder: (context, child) => Transform.translate(
              offset: wrongAttempt ? Offset(sin(shakeController.value * 15) * shakeAnimation.value, 0) : Offset.zero,
              child: child,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: wrongAttempt ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: wrongAttempt 
                        ? const Color(0xFFEF4444).withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    wrongAttempt ? 'Try Again' : 'Find the',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: wrongAttempt ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [currentTarget!.primaryColor, currentTarget!.accentColor],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentTarget!.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => speak(currentTarget!.name),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
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
        if (!allCompleted && currentTarget != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final item = options[index];
                  final isSelected = selectedItemId == item.id;
                  final isCorrect = item.id == currentTarget!.id;
                  final showResult = selectedItemId != null;

                  return GestureDetector(
                    onTap: selectedItemId == null ? () => handleItemSelection(item) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: showResult 
                              ? (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                              : const Color(0xFFE2E8F0),
                          width: showResult ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (showResult 
                                ? (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                : Colors.black)
                                .withOpacity(showResult ? 0.2 : 0.06),
                            blurRadius: showResult ? 20 : 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: item.imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                                  if (showResult)
                                    Container(
                                      color: (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                          .withOpacity(0.25),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            isCorrect ? Icons.check_rounded : Icons.close_rounded,
                                            size: 32,
                                            color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [item.primaryColor, item.accentColor],
                                ),
                              ),
                              child: Text(
                                item.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}