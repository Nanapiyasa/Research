const mongoose = require('mongoose');

const scenarioSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  level: {
    type: String,
    enum: ['level_1', 'level_2', 'level_3'],
    required: true
  },
  subLevel: {
    type: String,
    enum: ['beginner', 'intermediate', 'advanced'],
    required: true
  },
  category: {
    type: String,
    enum: ['greeting', 'conversation', 'social', 'community', 'workplace'],
    required: true
  },
  targetSkills: [{
    type: String
  }],
  setting: {
    location: { type: String },
    timeOfDay: { type: String },
    context: { type: String }
  },
  characters: [{
    id: { type: String },
    name: { type: String },
    role: { type: String },
    personality: { type: String },
    avatar: { type: String }
  }],
  dialogueFlow: {
    introduction: { type: String },
    expectedInteractions: { type: Number },
    successCriteria: [{
      skill: { type: String },
      threshold: { type: Number }
    }]
  },
  multimodal: {
    backgroundImage: { type: String },
    backgroundMusic: { type: String },
    soundEffects: [{ type: String }]
  },
  difficulty: {
    type: Number,
    min: 1,
    max: 10
  },
  estimatedDuration: {
    type: Number // in minutes
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

scenarioSchema.index({ level: 1, subLevel: 1, category: 1 });

module.exports = mongoose.model('Scenario', scenarioSchema);