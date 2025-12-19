const axios = require('axios');
const config = require('../../config/environment.config');
const { INTENTS } = require('../../config/constants');
const logger = require('../../utils/logger');

class IntentClassifier {
  constructor() {
    this.mlServiceUrl = config.mlServiceUrl;
    this.cache = new Map();
  }

  async classify(text) {
    try {
      // Check cache first
      const cacheKey = text.toLowerCase().trim();
      if (this.cache.has(cacheKey)) {
        return this.cache.get(cacheKey);
      }

      // Call ML service for classification
      const response = await axios.post(`${this.mlServiceUrl}/classify/intent`, {
        text: text
      });

      const result = {
        intent: response.data.intent,
        confidence: response.data.confidence,
        alternativeIntents: response.data.alternatives || []
      };

      // Cache result
      this.cache.set(cacheKey, result);

      return result;
    } catch (error) {
      logger.error('Intent classification error:', error);
      
      // Fallback to simple rule-based classification
      return this.fallbackClassification(text);
    }
  }

  fallbackClassification(text) {
    const lowerText = text.toLowerCase();

    // Simple keyword matching
    if (lowerText.match(/\b(hello|hi|hey|greetings)\b/)) {
      return { intent: INTENTS.GREETING, confidence: 0.8, alternativeIntents: [] };
    }
    if (lowerText.match(/\b(bye|goodbye|see you)\b/)) {
      return { intent: INTENTS.FAREWELL, confidence: 0.8, alternativeIntents: [] };
    }
    if (lowerText.match(/\b(please|can you|could you|would you)\b/)) {
      return { intent: INTENTS.REQUEST, confidence: 0.7, alternativeIntents: [] };
    }
    if (lowerText.match(/\b(what|where|when|who|why|how)\b/)) {
      return { intent: INTENTS.QUESTION, confidence: 0.7, alternativeIntents: [] };
    }
    if (lowerText.match(/\b(sorry|apologize|my bad)\b/)) {
      return { intent: INTENTS.APOLOGY, confidence: 0.8, alternativeIntents: [] };
    }
    if (lowerText.match(/\b(thanks|thank you|appreciate)\b/)) {
      return { intent: INTENTS.THANKS, confidence: 0.8, alternativeIntents: [] };
    }
    if (lowerText.match(/\b(yes|yeah|sure|okay|agree)\b/)) {
      return { intent: INTENTS.AGREEMENT, confidence: 0.7, alternativeIntents: [] };
    }
    if (lowerText.match(/\b(no|nope|disagree)\b/)) {
      return { intent: INTENTS.DISAGREEMENT, confidence: 0.7, alternativeIntents: [] };
    }

    return { intent: INTENTS.STATEMENT, confidence: 0.6, alternativeIntents: [] };
  }

  clearCache() {
    this.cache.clear();
  }
}

module.exports = new IntentClassifier();