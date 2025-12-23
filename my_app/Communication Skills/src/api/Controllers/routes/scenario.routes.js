
const express = require('express');
const router = express.Router();
const scenarioController = require('../controllers/scenarioController');
const authMiddleware = require('../middlewares/auth.middleware');

// Get all scenarios for a level
router.get(
  '/level/:level/sublevel/:subLevel',
  authMiddleware.authenticate,
  scenarioController.getScenariosByLevel
);

// Get specific scenario
router.get(
  '/:scenarioId',
  authMiddleware.authenticate,
  scenarioController.getScenario
);

// Get recommended scenarios for user
router.get(
  '/recommendations/:userId',
  authMiddleware.authenticate,
  scenarioController.getRecommendations
);

module.exports = router;