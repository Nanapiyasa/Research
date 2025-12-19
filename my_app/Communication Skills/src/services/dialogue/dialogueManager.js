const contextManager = require('./contextManager');
const responseGenerator = require('./responseGenerator');
const adaptiveEngine = require('./adaptiveEngine');
const logger = require('../../utils/logger');

class DialogueManager {
  constructor() {
    this.activeContexts = new Map();
  }

  // Initialize conversation context
  async initializeContext(conversationId, scenario, character) {
    const context = {
      conversationId,
      scenario,
      character,
      turnCount: 0,
      userProfile: {
        responsePatterns: [],
        skillLevels: new Map(),
        emotionalState: 'neutral'
      },
      dialogueState: {
        phase: 'introduction',
        completedTopics: [],
        currentTopic: scenario.dialogueFlow.introduction
      }
    };

    this.activeContexts.set(conversationId, context);
    await contextManager.saveContext(conversationId, context);
    
    return context;
  }

  // Generate contextual response
  async generateResponse(conversationId, userMessage, analysis) {
    try {
      let context = this.activeContexts.get(conversationId);
      
      if (!context) {
        context = await contextManager.loadContext(conversationId);
        this.activeContexts.set(conversationId, context);
      }

      // Update context with user analysis
      context.turnCount++;
      context.userProfile.emotionalState = analysis.emotion.emotion;
      context.userProfile.responsePatterns.push({
        message: userMessage,
        intent: analysis.intent.intent,
        quality: analysis.quality.score
      });

      // Adapt difficulty based on performance
      const adaptedDifficulty = await adaptiveEngine.adaptDifficulty(
        context.userProfile,
        context.scenario
      );

      // Generate appropriate response
      const response = await responseGenerator.generate(
        userMessage,
        context,
        analysis,
        adaptedDifficulty
      );

      // Update dialogue state
      context.dialogueState.phase = response.nextPhase || context.dialogueState.phase;
      
      // Save updated context
      this.activeContexts.set(conversationId, context);
      await contextManager.updateContext(conversationId, context);

      return response;
    } catch (error) {
      logger.error('Error in dialogue manager:', error);
      throw error;
    }
  }

  // Clean up context when conversation ends
  async cleanupContext(conversationId) {
    this.activeContexts.delete(conversationId);
    await contextManager.deleteContext(conversationId);
  }
}

module.exports = new DialogueManager();