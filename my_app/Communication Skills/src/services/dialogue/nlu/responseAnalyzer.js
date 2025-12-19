const { SKILLS } = require('../../config/constants');
const logger = require('../../utils/logger');

class ResponseAnalyzer {
  async analyze(text, targetSkills) {
    try {
      const analysis = {
        score: 0,
        skillsDetected: [],
        suggestions: [],
        strengths: [],
        improvements: []
      };

      // Analyze each target skill
      for (const skill of targetSkills) {
        const skillScore = await this.analyzeSkill(text, skill);
        if (skillScore.detected) {
          analysis.skillsDetected.push(skill);
          analysis.score += skillScore.score;
          analysis.strengths.push(...skillScore.strengths);
        } else {
          analysis.improvements.push(`Practice ${skill} more`);
        }
      }

      // Calculate average score
      analysis.score = targetSkills.length > 0
        ? Math.round(analysis.score / targetSkills.length)
        : 50;

      // Analyze basic communication quality
      const basicQuality = this.analyzeBasicQuality(text);
      analysis.score = Math.round((analysis.score + basicQuality.score) / 2);
      analysis.suggestions.push(...basicQuality.suggestions);

      return analysis;
    } catch (error) {
      logger.error('Response analysis error:', error);
      return {
        score: 50,
        skillsDetected: [],
        suggestions: ['Keep practicing!'],
        strengths: [],
        improvements: []
      };
    }
  }

  async analyzeSkill(text, skill) {
    const lowerText = text.toLowerCase();
    const result = {
      detected: false,
      score: 0,
      strengths: []
    };

    switch (skill) {
      case SKILLS.GREETINGS:
        if (lowerText.match(/\b(hello|hi|hey|good morning|good afternoon)\b/)) {
          result.detected = true;
          result.score = 85;
          result.strengths.push('Used appropriate greeting');
        }
        break;

      case SKILLS.EXPRESSING_NEEDS:
        if (lowerText.match(/\b(i need|i want|can i have|could i get)\b/)) {
          result.detected = true;
          result.score = 80;
          result.strengths.push('Clearly expressed needs');
        }
        break;

      case SKILLS.ASKING_QUESTIONS:
        if (lowerText.match(/\b(what|where|when|who|why|how|can|could|would)\b/) && 
            lowerText.includes('?')) {
          result.detected = true;
          result.score = 85;
          result.strengths.push('Asked a clear question');
        }
        break;

      case SKILLS.EMPATHY:
        if (lowerText.match(/\b(understand|feel|sorry|that must be|i can see)\b/)) {
          result.detected = true;
          result.score = 90;
          result.strengths.push('Showed empathy');
        }
        break;

      case SKILLS.TURN_TAKING:
        // This would be analyzed based on conversation flow
        result.detected = true;
        result.score = 75;
        break;

      default:
        result.detected = true;
        result.score = 70;
    }

    return result;
  }

  analyzeBasicQuality(text) {
    const quality = {
      score: 50,
      suggestions: []
    };

    // Check length
    const wordCount = text.trim().split(/\s+/).length;
    if (wordCount >= 3 && wordCount <= 20) {
      quality.score += 20;
    } else if (wordCount < 3) {
      quality.suggestions.push('Try to say a bit more');
    } else {
      quality.suggestions.push('Try to be more concise');
    }

    // Check for proper sentence structure
    if (text.trim().endsWith('.') || text.trim().endsWith('?') || text.trim().endsWith('!')) {
      quality.score += 15;
    }

    // Check for politeness markers
    if (text.toLowerCase().match(/\b(please|thank you|thanks|sorry)\b/)) {
      quality.score += 15;
      quality.suggestions.push('Great use of polite words!');
    }

    return quality;
  }
}

module.exports = new ResponseAnalyzer();