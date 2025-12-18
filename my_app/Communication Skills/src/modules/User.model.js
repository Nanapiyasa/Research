const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true
  },
  password: {
    type: String,
    required: true
  },
  role: {
    type: String,
    enum: ['child', 'parent', 'teacher', 'admin'],
    default: 'child'
  },
  profile: {
    firstName: { type: String, required: true },
    lastName: { type: String, required: true },
    age: { type: Number },
    dateOfBirth: { type: Date },
    avatar: { type: String, default: 'default-avatar.png' },
    preferredLanguage: { type: String, enum: ['en', 'si', 'ta'], default: 'en' },
    voicePreference: { type: String, enum: ['male', 'female', 'child'], default: 'female' }
  },
  settings: {
    soundEnabled: { type: Boolean, default: true },
    musicEnabled: { type: Boolean, default: true },
    textSize: { type: String, enum: ['small', 'medium', 'large'], default: 'medium' },
    animationSpeed: { type: String, enum: ['slow', 'normal', 'fast'], default: 'normal' }
  },
  currentLevel: {
    level: { type: String, default: 'level_1' },
    subLevel: { type: String, default: 'beginner' }
  },
  parentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  createdAt: { type: Date, default: Date.now },
  lastActive: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', userSchema);