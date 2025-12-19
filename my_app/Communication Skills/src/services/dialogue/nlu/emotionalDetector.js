
const axios = require('axios');
const config = require('../../config/environment.config');
const { EMOTIONS } = require('../../config/constants');
const logger = require('../../utils/logger');

class EmotionDetector {
  constructor() {
    this.mlServiceUrl = config.mlServiceUrl;
  }

  async detect(text) {
    try {
      const response = await axios.post(`${this.mlServiceUrl}/detect/emotion`, {
        text: text
      });

      return {
        emotion: response.data.emotion,
        confidence: response.data.confidence,
        sentiment: response.data.sentiment, // -1 to 1
        valence: response.data.valence, // emotional intensity
        arousal: response.data.arousal // activation level
      };
    } catch (error) {
      logger.error('Emotion detection error:', error);
      
      // Fallback to simple sentiment analysis
      return this.fallbackDetection(text);
    }
  }

  fallbackDetection(text) {
    const lowerText = text.toLowerCase();

    // Positive emotion keywords
    const happyWords = ['happy', 'great', 'good', 'wonderful', 'excellent', 'love', 'joy', 'excited'];
    const sadWords = ['sad', 'unhappy', 'upset', 'disappointed', 'hurt', 'lonely'];
    const angryWords = ['angry', 'mad', 'furious', 'annoyed', 'frustrated'];
    const confusedWords = ['confused', 'unsure', 'don\'t know', 'puzzled'];

    let emotion = EMOTIONS.NEUTRAL;
    let sentiment = 0;

    if (happyWords.some(word => lowerText.includes(word))) {
      emotion = EMOTIONS.HAPPY;
      sentiment = 0.7;
    } else if (sadWords.some(word => lowerText.includes(word))) {
      emotion = EMOTIONS.SAD;
      sentiment = -0.6;
    } else if (angryWords.some(word => lowerText.includes(word))) {
      emotion = EMOTIONS.ANGRY;
      sentiment = -0.7;
    } else if (confusedWords.some(word => lowerText.includes(word))) {
      emotion = EMOTIONS.CONFUSED;
      sentiment = -0.3;
    }

    return {
      emotion,
      confidence: 0.6,
      sentiment,
      valence: Math.abs(sentiment),
      arousal: sentiment !== 0 ? 0.5 : 0.2
    };
  }
}

module.exports = new EmotionDetector();