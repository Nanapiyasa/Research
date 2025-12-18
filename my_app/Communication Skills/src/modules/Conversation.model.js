const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  sender: {
    type: String,
    enum: ['user', 'bot'],
    required: true
  },
  content: {
    text: { type: String, required: true },
    audio: { type: String } // URL to audio file
  },
  timestamp: {
    type: Date,
    default: Date.now
  },
  analysis: {
    intent: { type: String },
    emotion: { type: String },
    sentiment: { type: Number, min: -1, max: 1 },
    skillsUsed: [{ type: String }],
    responseQuality: { type: Number, min: 0, max: 100 }
  }
});

const conversationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  scenarioId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Scenario',
    required: true
  },
  characterId: {
    type: String,
    required: true
  },
  messages: [messageSchema],
  status: {
    type: String,
    enum: ['active', 'completed', 'abandoned'],
    default: 'active'
  },
  duration: {
    type: Number, // in seconds
    default: 0
  },
  assessment: {
    overallScore: { type: Number, min: 0, max: 100 },
    skillScores: {
      type: Map,
      of: Number
    },
    feedback: { type: String },
    recommendations: [{ type: String }]
  },
  startedAt: {
    type: Date,
    default: Date.now
  },
  completedAt: {
    type: Date
  }
});

conversationSchema.index({ userId: 1, startedAt: -1 });

module.exports = mongoose.model('Conversation', conversationSchema);