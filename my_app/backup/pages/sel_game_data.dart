// lib/pages/sel_game_data.dart
import 'package:flutter/material.dart';
import 'sel_game_model.dart';

class SELGameData {
  static List<SELScenario> getScenarios() {
    return [
      // ==================== BEGINNER LEVEL ====================
      // Empathy - Beginner
      SELScenario(
        id: 'emp_b1',
        skill: SELSkill.empathy,
        level: SELGameLevel.beginner,
        title: '😊 A Friend is Sad',
        description: 'Your friend is sitting alone and looks sad. What would make them feel better?',
        imageAsset: '🎭',
        options: [
          SELOption(
            text: 'Sit with them and ask if they want to talk',
            isCorrect: true,
            explanation: 'Showing you care by being there helps friends feel supported!',
            icon: Icons.favorite,
          ),
          SELOption(
            text: 'Ignore them and play with others',
            isCorrect: false,
            explanation: 'Everyone needs support sometimes. Being there matters!',
            icon: Icons.not_interested,
          ),
          SELOption(
            text: 'Tell them to cheer up',
            isCorrect: false,
            explanation: 'It\'s better to listen than to tell someone how to feel.',
            icon: Icons.volume_up,
          ),
          SELOption(
            text: 'Make fun of them',
            isCorrect: false,
            explanation: 'Making fun of sad feelings can hurt deeply.',
            icon: Icons.sentiment_very_dissatisfied,
          ),
        ],
        feedback: '💝 You showed great empathy! Friends feel better when we listen.',
        xpReward: 15,
      ),

      SELScenario(
        id: 'emp_b2',
        skill: SELSkill.empathy,
        level: SELGameLevel.beginner,
        title: '🎒 New Student',
        description: 'A new student joins your class and looks nervous. What could you do?',
        imageAsset: '👋',
        options: [
          SELOption(
            text: 'Smile and say hello',
            isCorrect: true,
            explanation: 'A simple hello can make someone feel welcome!',
            icon: Icons.waving_hand,
          ),
          SELOption(
            text: 'Stare at them',
            isCorrect: false,
            explanation: 'Staring might make them more uncomfortable.',
            icon: Icons.visibility,
          ),
          SELOption(
            text: 'Whisper about them',
            isCorrect: false,
            explanation: 'Talking about others can hurt feelings.',
            icon: Icons.comment,
          ),
          SELOption(
            text: 'Ignore them completely',
            isCorrect: false,
            explanation: 'Everyone wants to feel noticed and welcomed.',
            icon: Icons.remove_circle,
          ),
        ],
        feedback: '🌟 Great job! Small acts of kindness make big differences!',
        xpReward: 15,
      ),

      // Self-Awareness - Beginner
      SELScenario(
        id: 'self_b1',
        skill: SELSkill.selfAwareness,
        level: SELGameLevel.beginner,
        title: '😤 Feeling Angry',
        description: 'Your brother took your toy without asking. How do you feel?',
        imageAsset: '😠',
        options: [
          SELOption(
            text: 'Angry and frustrated',
            isCorrect: true,
            explanation: 'Yes! It\'s normal to feel angry when someone takes your things.',
            icon: Icons.emoji_emotions,
          ),
          SELOption(
            text: 'Happy',
            isCorrect: false,
            explanation: 'It\'s okay to feel unhappy when something unfair happens.',
            icon: Icons.sentiment_satisfied,
          ),
          SELOption(
            text: 'Scared',
            isCorrect: false,
            explanation: 'You might feel angry, not scared, when your things are taken.',
            icon: Icons.mood_bad,
          ),
          SELOption(
            text: 'Nothing at all',
            isCorrect: false,
            explanation: 'It\'s natural to have feelings about things that happen to us.',
            icon: Icons.sentiment_neutral,
          ),
        ],
        feedback: '🎯 Great self-awareness! Recognizing your feelings is the first step!',
        xpReward: 15,
      ),

      // Emotional Regulation - Beginner
      SELScenario(
        id: 'emo_b1',
        skill: SELSkill.emotionalRegulation,
        level: SELGameLevel.beginner,
        title: '😰 Feeling Nervous',
        description: 'You have to speak in front of the class. You feel nervous. What helps?',
        imageAsset: '🎤',
        options: [
          SELOption(
            text: 'Take deep breaths',
            isCorrect: true,
            explanation: 'Deep breathing calms your body and mind!',
            icon: Icons.air,
          ),
          SELOption(
            text: 'Run away',
            isCorrect: false,
            explanation: 'Facing fears helps you grow stronger.',
            icon: Icons.directions_run,
          ),
          SELOption(
            text: 'Cry loudly',
            isCorrect: false,
            explanation: 'There are better ways to calm down.',
            icon: Icons.sentiment_dissatisfied,
          ),
          SELOption(
            text: 'Hide under desk',
            isCorrect: false,
            explanation: 'You can face this with courage!',
            icon: Icons.visibility_off,
          ),
        ],
        feedback: '💪 Excellent! Deep breathing helps you stay calm and confident!',
        xpReward: 15,
      ),

      // ==================== INTERMEDIATE LEVEL ====================
      SELScenario(
        id: 'soc_i1',
        skill: SELSkill.socialSkills,
        level: SELGameLevel.intermediate,
        title: '🤝 Making Friends',
        description: 'You see someone sitting alone at lunch. What\'s the best way to invite them?',
        imageAsset: '🍽️',
        options: [
          SELOption(
            text: 'Smile and say "Want to join us?"',
            isCorrect: true,
            explanation: 'A friendly invitation makes people feel welcome!',
            icon: Icons.food_bank,
          ),
          SELOption(
            text: 'Yell "Come here!"',
            isCorrect: false,
            explanation: 'Being too loud might scare them away.',
            icon: Icons.volume_up,
          ),
          SELOption(
            text: 'Ignore them',
            isCorrect: false,
            explanation: 'Everyone deserves a chance to make friends.',
            icon: Icons.person_off,
          ),
          SELOption(
            text: 'Send a friend to get them',
            isCorrect: false,
            explanation: 'It\'s nice to invite them yourself!',
            icon: Icons.send,
          ),
        ],
        feedback: '🤗 Perfect! A warm smile and kind words open doors to friendship!',
        xpReward: 20,
      ),

      SELScenario(
        id: 'prob_i1',
        skill: SELSkill.problemSolving,
        level: SELGameLevel.intermediate,
        title: '🧩 Broken Toy',
        description: 'Your favorite toy breaks. What\'s the best way to solve this?',
        imageAsset: '🔧',
        options: [
          SELOption(
            text: 'Ask an adult for help fixing it',
            isCorrect: true,
            explanation: 'Asking for help is smart problem-solving!',
            icon: Icons.build,
          ),
          SELOption(
            text: 'Throw it away and cry',
            isCorrect: false,
            explanation: 'There might be a way to fix it with help.',
            icon: Icons.delete,
          ),
          SELOption(
            text: 'Blame someone else',
            isCorrect: false,
            explanation: 'Focus on solutions, not blame.',
            icon: Icons.gavel,
          ),
          SELOption(
            text: 'Forget about it',
            isCorrect: false,
            explanation: 'You could try to fix it first!',
            icon: Icons.memory,
          ),
        ],
        feedback: '🔨 Great problem-solving! Getting help is always a good idea!',
        xpReward: 20,
      ),

      // ==================== ADVANCED LEVEL ====================
      SELScenario(
        id: 'emp_a1',
        skill: SELSkill.empathy,
        level: SELGameLevel.advanced,
        title: '🌈 Friend in Trouble',
        description: 'Your friend is being bullied. They look very upset. What should you do?',
        imageAsset: '🛡️',
        options: [
          SELOption(
            text: 'Stand with them and tell a teacher',
            isCorrect: true,
            explanation: 'Supporting friends and getting help is brave!',
            icon: Icons.support,
          ),
          SELOption(
            text: 'Join the bullies',
            isCorrect: false,
            explanation: 'Being part of bullying hurts everyone.',
            icon: Icons.groups,
          ),
          SELOption(
            text: 'Walk away and pretend not to see',
            isCorrect: false,
            explanation: 'Your friend needs you now more than ever.',
            icon: Icons.directions_walk,
          ),
          SELOption(
            text: 'Tell them to fight back',
            isCorrect: false,
            explanation: 'Fighting can make things worse.',
            icon: Icons.sports_mma,
          ),
        ],
        feedback: '🦸 You\'re a true hero! Standing up for others takes courage and empathy!',
        xpReward: 25,
      ),

      SELScenario(
        id: 'emo_a1',
        skill: SELSkill.emotionalRegulation,
        level: SELGameLevel.advanced,
        title: '🎮 Losing a Game',
        description: 'You lost an important game. You feel like crying and yelling. What\'s the healthiest response?',
        imageAsset: '🏆',
        options: [
          SELOption(
            text: 'Take deep breaths, then congratulate the winner',
            isCorrect: true,
            explanation: 'Managing disappointment with grace shows true character!',
            icon: Icons.sports_score,
          ),
          SELOption(
            text: 'Throw your controller',
            isCorrect: false,
            explanation: 'Breaking things doesn\'t fix feelings.',
            icon: Icons.sports_esports,
          ),
          SELOption(
            text: 'Blame teammates',
            isCorrect: false,
            explanation: 'Taking responsibility helps you grow.',
            icon: Icons.people,
          ),
          SELOption(
            text: 'Quit and never play again',
            isCorrect: false,
            explanation: 'Everyone loses sometimes. Learning from it matters!',
            icon: Icons.exit_to_app,
          ),
        ],
        feedback: '🏅 Amazing! Being a good sport shows emotional strength!',
        xpReward: 25,
      ),

      // ==================== EXPERT LEVEL ====================
      SELScenario(
        id: 'social_x1',
        skill: SELSkill.socialSkills,
        level: SELGameLevel.expert,
        title: '💔 Friendship Problem',
        description: 'Your best friend is angry because you forgot their birthday. How do you handle this?',
        imageAsset: '🎂',
        options: [
          SELOption(
            text: 'Apologize sincerely and plan a make-up celebration',
            isCorrect: true,
            explanation: 'Taking responsibility and making amends strengthens friendships!',
            icon: Icons.cake,
          ),
          SELOption(
            text: 'Get angry back at them',
            isCorrect: false,
            explanation: 'Two wrongs don\'t make a right.',
            icon: Icons.thumb_down,
          ),
          SELOption(
            text: 'Ignore them until they calm down',
            isCorrect: false,
            explanation: 'Ignoring problems makes them worse.',
            icon: Icons.notifications_off,
          ),
          SELOption(
            text: 'Buy an expensive gift',
            isCorrect: false,
            explanation: 'A sincere apology means more than gifts.',
            icon: Icons.card_giftcard,
          ),
        ],
        feedback: '💖 True friendship grows stronger when we apologize and make things right!',
        xpReward: 30,
      ),

      SELScenario(
        id: 'prob_x1',
        skill: SELSkill.problemSolving,
        level: SELGameLevel.expert,
        title: '🚨 Emergency Situation',
        description: 'You see someone fall and hurt themselves badly. No adults are around. What do you do?',
        imageAsset: '🚑',
        options: [
          SELOption(
            text: 'Call emergency services and stay with them',
            isCorrect: true,
            explanation: 'Getting help and staying calm saves lives!',
            icon: Icons.local_hospital,
          ),
          SELOption(
            text: 'Panic and run away',
            isCorrect: false,
            explanation: 'Staying calm and getting help is crucial.',
            icon: Icons.pan_tool,
          ),
          SELOption(
            text: 'Try to move them',
            isCorrect: false,
            explanation: 'Moving an injured person can hurt them more.',
            icon: Icons.accessible,
          ),
          SELOption(
            text: 'Wait for someone else to help',
            isCorrect: false,
            explanation: 'You can be the one who helps!',
            icon: Icons.timer,
          ),
        ],
        feedback: '🦸‍♀️ You\'re a hero! Quick thinking and calm action save the day!',
        xpReward: 30,
      ),
    ];
  }

  static List<SELScenario> getScenariosByLevel(SELGameLevel level) {
    return getScenarios().where((s) => s.level == level).toList();
  }

  static List<SELScenario> getScenariosBySkill(SELSkill skill) {
    return getScenarios().where((s) => s.skill == skill).toList();
  }

  static Map<SELGameLevel, int> getLevelProgress(List<SELScenario> completed) {
    Map<SELGameLevel, int> progress = {};
    for (var level in SELGameLevel.values) {
      var total = getScenariosByLevel(level).length;
      var completed_count = completed.where((s) => s.level == level).length;
      progress[level] = total > 0 ? (completed_count * 100 ~/ total) : 0;
    }
    return progress;
  }
}