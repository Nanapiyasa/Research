const { INTENTS, EMOTIONS, FEEDBACK_TYPES } = require('../../config/constants');
const logger = require('../../utils/logger');

class ResponseGenerator {
  constructor() {
    this.responseTemplates = this.loadResponseTemplates();
  }

  loadResponseTemplates() {
    return {
      greeting: {
        positive: [
          "Hello! It's great to talk with you!",
          "Hi there! I'm happy to see you!",
          "Hey! How are you doing today?"
        ],
        neutral: [
          "Hello! How can I help you?",
          "Hi! What would you like to talk about?"
        ]
      },
      encouragement: {
        low_quality: [
          "That's a good try! Let me help you say that better.",
          "I can see you're trying. Let's practice together!",
          "Good effort! Here's another way to say it:"
        ],
        medium_quality: [
          "Nice! You're doing well. Keep going!",
          "Good job! You're getting better at this.",
          "That's right! You're on the right track!"
        ],
        high_quality: [
          "Excellent! You said that perfectly!",
          "Wonderful! That was exactly right!",
          "Amazing work! You're a great communicator!"
        ]
      },
      correction: {
        gentle: [
          "That's close! Try saying it like this:",
          "I understand! Another way to say it is:",
          "Good try! Let me show you:"
        ]
      },
      question_prompt: [
        "Can you tell me more about that?",
        "What do you think about...?",
        "How do you feel about...?"
      ]
    };
  }

  async generate(userMessage, context, analysis, difficulty) {
    const { intent, emotion, quality } = analysis;
    const { character, scenario, dialogueState } = context;

    // Determine response type based on quality
    let responseType = this.determineResponseType(quality.score);
    
    // Select appropriate template
    let responseText = this.selectResponse(
      intent.intent,
      emotion.emotion,
      quality.score,
      character
    );

    // Add contextual information
    responseText = this.addContextualElements(
      responseText,
      dialogueState,
      scenario
    );

    // Generate feedback
    const feedback = this.generateFeedback(quality, intent, emotion);

    // Determine next dialogue phase
    const nextPhase = this.determineNextPhase(
      dialogueState.phase,
      context.turnCount,
      scenario
    );

    return {
      text: responseText,
      feedback,
      nextPhase,
      shouldEnd: this.shouldEndConversation(context, scenario)
    };
  }

  determineResponseType(qualityScore) {
    if (qualityScore >= 80) return 'high_quality';
    if (qualityScore >= 50) return 'medium_quality';
    return 'low_quality';
  }

  selectResponse(intent, emotion, qualityScore, character) {
    // Handle different intents
    if (intent === INTENTS.GREETING) {
      const greetings = this.responseTemplates.greeting.positive;
      return this.randomSelect(greetings);
    }

    if (intent === INTENTS.FAREWELL) {
      return `Goodbye! It was nice talking to you. See you next time!`;
    }

    // Provide encouragement based on quality
    if (qualityScore >= 80) {
      return this.randomSelect(this.responseTemplates.encouragement.high_quality);
    } else if (qualityScore >= 50) {
      return this.randomSelect(this.responseTemplates.encouragement.medium_quality);
    } else {
      const encouragement = this.randomSelect(this.responseTemplates.encouragement.low_quality);
      const correction = this.randomSelect(this.responseTemplates.correction.gentle);
      return `${encouragement} ${correction}`;
    }
  }

  addContextualElements(baseResponse, dialogueState, scenario) {
    // Add scenario-specific context
    if (scenario.setting && scenario.setting.location) {
      // Contextual awareness
      if (dialogueState.phase === 'introduction') {
        return `${baseResponse} We're at the ${scenario.setting.location}.`;
      }
    }

    return baseResponse;
  }

  generateFeedback(quality, intent, emotion) {
    const feedback = {
      type: quality.score >= 70 ? FEEDBACK_TYPES.POSITIVE : FEEDBACK_TYPES.ENCOURAGING,
      message: '',
      suggestions: []
    };

    if (quality.score >= 80) {
      feedback.message = '✨ Great communication!';
    } else if (quality.score >= 60) {
      feedback.message = '👍 Good job! Keep practicing!';
      feedback.suggestions.push('Try to be more specific in your responses');
    } else {
      feedback.message = '💪 You can do it! Let\'s try again.';
      feedback.suggestions.push('Think about what you want to say');
      feedback.suggestions.push('Take your time to respond');
    }

    return feedback;
  }

  determineNextPhase(currentPhase, turnCount, scenario) {
    if (currentPhase === 'introduction' && turnCount >= 3) {
      return 'main_conversation';
    }
    if (currentPhase === 'main_conversation' && turnCount >= scenario.dialogueFlow.expectedInteractions) {
      return 'conclusion';
    }
    return currentPhase;
  }

  shouldEndConversation(context, scenario) {
    return context.turnCount >= scenario.dialogueFlow.expectedInteractions + 2;
  }

  randomSelect(array) {
    return array[Math.floor(Math.random() * array.length)];
  }
}

module.exports = new ResponseGenerator();