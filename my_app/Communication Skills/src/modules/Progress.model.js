const mongoose = require('mongoose');

const skillProgressSchema = new mongoose.Schema({
  skillName: { type: String, required: true },
  currentLevel: { type: Number, default: 0 },
  practiceCount: { type: Number, default: 0 },
  successRate: { type: Number, default: 0 },
  lastPracticed: { type: Date },
  milestones: [{
    achieved: { type: Boolean, default: false },
    achievedAt: { type: Date },
    description: { type: String }
  }]
});

const progressSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  overallProgress: {
    level: { type: String, default: 'level_1' },
    subLevel: { type: String, default: 'beginner' },
    completionPercentage: { type: Number, default: 0 }
  },
  skillsProgress: [skillProgressSchema],
  scenariosCompleted: [{
    scenarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'Scenario' },
    completedAt: { type: Date },
    score: { type: Number },
    attempts: { type: Number, default: 1 }
  }],
  badges: [{
    badgeId: { type: String },
    name: { type: String },
    description: { type: String },
    earnedAt: { type: Date },
    icon: { type: String }
  }],
  streaks: {
    currentStreak: { type: Number, default: 0 },
    longestStreak: { type: Number, default: 0 },
    lastActivityDate: { type: Date }
  },
  statistics: {
    totalConversations: { type: Number, default: 0 },
    totalMessages: { type: Number, default: 0 },
    averageSessionDuration: { type: Number, default: 0 },
    favoriteScenarios: [{ type: String }]
  },
  recommendations: [{
    scenarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'Scenario' },
    reason: { type: String },
    priority: { type: Number }
  }],
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

progressSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Progress', progressSchema);