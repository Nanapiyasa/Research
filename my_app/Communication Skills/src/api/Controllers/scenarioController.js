
const Scenario = require('../../models/Scenario.model');
const Progress = require('../../models/Progress.model');
const logger = require('../../utils/logger');

class ScenarioController {
  async getScenariosByLevel(req, res) {
    try {
      const { level, subLevel } = req.params;

      const scenarios = await Scenario.find({
        level,
        subLevel,
        isActive: true
      }).sort({ difficulty: 1 });

      res.json({
        level,
        subLevel,
        scenarios
      });
    } catch (error) {
      logger.error('Error fetching scenarios:', error);
      res.status(500).json({ error: 'Failed to fetch scenarios' });
    }
  }

  async getScenario(req, res) {
    try {
      const { scenarioId } = req.params;

      const scenario = await Scenario.findById(scenarioId);

      if (!scenario) {
        return res.status(404).json({ error: 'Scenario not found' });
      }

      res.json(scenario);
    } catch (error) {
      logger.error('Error fetching scenario:', error);
      res.status(500).json({ error: 'Failed to fetch scenario' });
    }
  }

  async getRecommendations(req, res) {
    try {
      const { userId } = req.params;

      const progress = await Progress.findOne({ userId })
        .populate('recommendations.scenarioId');

      if (!progress || progress.recommendations.length === 0) {
        // Get beginner level scenarios as default
        const defaultScenarios = await Scenario.find({
          level: 'level_1',
          subLevel: 'beginner',
          isActive: true
        }).limit(3);

        return res.json({
          recommendations: defaultScenarios.map(s => ({
            scenario: s,
            reason: 'Great starting point!',
            priority: 1
          }))
        });
      }

      res.json({
        recommendations: progress.recommendations
      });
    } catch (error) {
      logger.error('Error fetching recommendations:', error);
      res.status(500).json({ error: 'Failed to fetch recommendations' });
    }
  }
}

module.exports = new ScenarioController();