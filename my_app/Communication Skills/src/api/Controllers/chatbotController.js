const Conversation = require('../../models/Conversation.model');
const Scenario = require('../../models/Scenario.model');
const dialogueManager = require('../../services/dialogue/dialogueManager');
const intentClassifier = require('../../services/nlu/intentClassifier');
const emotionDetector = require('../../services/nlu/emotionDetector');
const responseAnalyzer = require('../../services/nlu/responseAnalyzer');
const logger = require('../../utils/logger');

class ChatbotController {
  // Start a new conversation
  async startConversation(req, res) {
    try {
      const { userId, scenarioId, characterId } = req.body;

      // Validate scenario exists
      const scenario = await Scenario.findById(scenarioId);
      if (!scenario) {
        return res.status(404).json({ error: 'Scenario not found' });
      }

      // Create new conversation
      const conversation = new Conversation({
        userId,
        scenarioId,
        characterId,
        status: 'active'
      });

      // Generate initial bot message
      const character = scenario.characters.find(c => c.id === characterId);
      const initialMessage = {
        sender: 'bot',
        content: {
          text: scenario.dialogueFlow.introduction || `Hello! I'm ${character.name}. ${scenario.description}`
        },
        timestamp: new Date()
      };

      conversation.messages.push(initialMessage);
      await conversation.save();

      // Initialize dialogue context
      await dialogueManager.initializeContext(conversation._id, scenario, character);

      res.status(201).json({
        conversationId: conversation._id,
        initialMessage: initialMessage,
        scenario: {
          title: scenario.title,
          description: scenario.description,
          setting: scenario.setting
        }
      });
    } catch (error) {
      logger.error('Error starting conversation:', error);
      res.status(500).json({ error: 'Failed to start conversation' });
    }
  }

  // Process user message and generate bot response
  async sendMessage(req, res) {
    try {
      const { conversationId } = req.params;
      const { message, audioUrl } = req.body;

      const conversation = await Conversation.findById(conversationId)
        .populate('scenarioId');

      if (!conversation) {
        return res.status(404).json({ error: 'Conversation not found' });
      }

      // Analyze user message
      const [intent, emotion, quality] = await Promise.all([
        intentClassifier.classify(message),
        emotionDetector.detect(message),
        responseAnalyzer.analyze(message, conversation.scenarioId.targetSkills)
      ]);

      // Create user message
      const userMessage = {
        sender: 'user',
        content: {
          text: message,
          audio: audioUrl
        },
        timestamp: new Date(),
        analysis: {
          intent: intent.intent,
          emotion: emotion.emotion,
          sentiment: emotion.sentiment,
          skillsUsed: quality.skillsDetected,
          responseQuality: quality.score
        }
      };

      conversation.messages.push(userMessage);

      // Generate bot response
      const botResponse = await dialogueManager.generateResponse(
        conversationId,
        message,
        {
          intent,
          emotion,
          quality
        }
      );

      const botMessage = {
        sender: 'bot',
        content: {
          text: botResponse.text
        },
        timestamp: new Date()
      };

      conversation.messages.push(botMessage);
      await conversation.save();

      // Emit real-time message via Socket.IO
      const io = req.app.get('io');
      io.to(conversationId).emit('new_message', botMessage);

      res.json({
        userMessage,
        botMessage,
        analysis: userMessage.analysis,
        feedback: botResponse.feedback
      });
    } catch (error) {
      logger.error('Error processing message:', error);
      res.status(500).json({ error: 'Failed to process message' });
    }
  }

  // End conversation and generate assessment
  async endConversation(req, res) {
    try {
      const { conversationId } = req.params;

      const conversation = await Conversation.findById(conversationId)
        .populate('scenarioId');

      if (!conversation) {
        return res.status(404).json({ error: 'Conversation not found' });
      }

      // Calculate duration
      const duration = Math.floor((Date.now() - conversation.startedAt) / 1000);
      conversation.duration = duration;
      conversation.status = 'completed';
      conversation.completedAt = new Date();

      // Generate assessment
      const assessment = await this.generateAssessment(conversation);
      conversation.assessment = assessment;

      await conversation.save();

      res.json({
        conversationId,
        duration,
        assessment
      });
    } catch (error) {
      logger.error('Error ending conversation:', error);
      res.status(500).json({ error: 'Failed to end conversation' });
    }
  }

  // Generate assessment from conversation
  async generateAssessment(conversation) {
    const userMessages = conversation.messages.filter(m => m.sender === 'user');
    
    if (userMessages.length === 0) {
      return {
        overallScore: 0,
        skillScores: new Map(),
        feedback: 'Not enough interaction to assess',
        recommendations: []
      };
    }

    // Calculate skill scores
    const skillScores = new Map();
    const targetSkills = conversation.scenarioId.targetSkills;

    targetSkills.forEach(skill => {
      const relevantMessages = userMessages.filter(m => 
        m.analysis.skillsUsed && m.analysis.skillsUsed.includes(skill)
      );

      if (relevantMessages.length > 0) {
        const avgScore = relevantMessages.reduce((sum, m) => 
          sum + (m.analysis.responseQuality || 0), 0
        ) / relevantMessages.length;
        skillScores.set(skill, Math.round(avgScore));
      } else {
        skillScores.set(skill, 0);
      }
    });

    // Calculate overall score
    const scores = Array.from(skillScores.values());
    const overallScore = scores.length > 0 
      ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length)
      : 0;

    // Generate feedback
    const feedback = this.generateFeedback(overallScore, skillScores);

    // Generate recommendations
    const recommendations = this.generateRecommendations(skillScores, conversation.scenarioId);

    return {
      overallScore,
      skillScores,
      feedback,
      recommendations
    };
  }

  generateFeedback(overallScore, skillScores) {
    if (overallScore >= 80) {
      return 'Excellent work! You demonstrated strong communication skills.';
    } else if (overallScore >= 60) {
      return 'Good effort! Keep practicing to improve your skills.';
    } else {
      return 'Nice try! Let\'s practice more to build your confidence.';
    }
  }

  generateRecommendations(skillScores, scenario) {
    const recommendations = [];
    
    skillScores.forEach((score, skill) => {
      if (score < 60) {
        recommendations.push(`Practice more ${skill} scenarios to improve.`);
      }
    });

    if (recommendations.length === 0) {
      recommendations.push('Try the next level to challenge yourself!');
    }

    return recommendations;
  }

  // Get conversation history
  async getConversation(req, res) {
    try {
      const { conversationId } = req.params;

      const conversation = await Conversation.findById(conversationId)
        .populate('scenarioId')
        .populate('userId', 'username profile');

      if (!conversation) {
        return res.status(404).json({ error: 'Conversation not found' });
      }

      res.json(conversation);
    } catch (error) {
      logger.error('Error fetching conversation:', error);
      res.status(500).json({ error: 'Failed to fetch conversation' });
    }
  }
}

module.exports = new ChatbotController();