const express = require('express');
const router = express.Router();
const chatbotController = require('../controllers/chatbotController');
const authMiddleware = require('../middlewares/auth.middleware');
const validationMiddleware = require('../middlewares/validation.middleware');

// Start new conversation
router.post(
  '/conversations',
  authMiddleware.authenticate,
  validationMiddleware.validateStartConversation,
  chatbotController.startConversation
);

// Send message in conversation
router.post(
  '/conversations/:conversationId/messages',
  authMiddleware.authenticate,
  validationMiddleware.validateMessage,
  chatbotController.sendMessage
);

// End conversation
router.post(
  '/conversations/:conversationId/end',
  authMiddleware.authenticate,
  chatbotController.endConversation
);

// Get conversation details
router.get(
  '/conversations/:conversationId',
  authMiddleware.authenticate,
  chatbotController.getConversation
);

module.exports = router;