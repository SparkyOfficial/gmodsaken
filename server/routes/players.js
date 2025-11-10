const express = require('express');
const router = express.Router();
const playerService = require('../services/playerService');

/**
 * GET /api/players/leaderboard
 * Get leaderboard
 * NOTE: This must be defined before /:steamid to avoid route conflicts
 */
router.get('/leaderboard', async (req, res) => {
  try {
    const sortBy = req.query.sortBy || 'xp';
    const limit = parseInt(req.query.limit) || 100;
    
    const leaderboard = await playerService.getLeaderboard(sortBy, limit);
    
    res.json({
      success: true,
      data: leaderboard,
      count: leaderboard.length,
      sortBy
    });
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    
    if (error.message.includes('Invalid sort field')) {
      return res.status(400).json({
        success: false,
        error: error.message
      });
    }
    
    if (error.message.includes('Limit must be between')) {
      return res.status(400).json({
        success: false,
        error: error.message
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Failed to fetch leaderboard'
    });
  }
});

/**
 * GET /api/players/:steamid
 * Get player profile by Steam ID
 */
router.get('/:steamid', async (req, res) => {
  try {
    const { steamid } = req.params;
    const player = await playerService.getPlayerProfile(steamid);
    
    res.json({
      success: true,
      data: player
    });
  } catch (error) {
    console.error('Error fetching player profile:', error);
    
    if (error.message === 'Player not found') {
      return res.status(404).json({
        success: false,
        error: 'Player not found'
      });
    }
    
    if (error.message === 'Invalid Steam ID format') {
      return res.status(400).json({
        success: false,
        error: 'Invalid Steam ID format'
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Failed to fetch player profile'
    });
  }
});

/**
 * PUT /api/players/:steamid
 * Update player profile statistics
 */
router.put('/:steamid', async (req, res) => {
  try {
    const { steamid } = req.params;
    const stats = req.body;
    
    const player = await playerService.updatePlayerStats(steamid, stats);
    
    res.json({
      success: true,
      data: player,
      message: 'Player stats updated successfully'
    });
  } catch (error) {
    console.error('Error updating player stats:', error);
    
    if (error.message === 'Player not found') {
      return res.status(404).json({
        success: false,
        error: 'Player not found'
      });
    }
    
    if (error.message === 'Invalid Steam ID format') {
      return res.status(400).json({
        success: false,
        error: 'Invalid Steam ID format'
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Failed to update player stats'
    });
  }
});

/**
 * POST /api/players/:steamid/xp
 * Add XP to player
 */
router.post('/:steamid/xp', async (req, res) => {
  try {
    const { steamid } = req.params;
    const { amount, reason } = req.body;
    
    if (!amount || typeof amount !== 'number') {
      return res.status(400).json({
        success: false,
        error: 'XP amount is required and must be a number'
      });
    }
    
    const result = await playerService.addPlayerXP(steamid, amount, reason);
    
    res.json({
      success: true,
      data: result,
      message: result.leveledUp 
        ? `Player leveled up to level ${result.newLevel}!` 
        : 'XP added successfully'
    });
  } catch (error) {
    console.error('Error adding player XP:', error);
    
    if (error.message === 'Player not found') {
      return res.status(404).json({
        success: false,
        error: 'Player not found'
      });
    }
    
    if (error.message === 'Invalid Steam ID format') {
      return res.status(400).json({
        success: false,
        error: 'Invalid Steam ID format'
      });
    }
    
    if (error.message === 'XP amount must be a positive number') {
      return res.status(400).json({
        success: false,
        error: error.message
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Failed to add XP'
    });
  }
});

/**
 * POST /api/players/:steamid/quests
 * Record quest completion
 */
router.post('/:steamid/quests', async (req, res) => {
  try {
    const { steamid } = req.params;
    const { questName, xpReward } = req.body;
    
    if (!questName) {
      return res.status(400).json({
        success: false,
        error: 'Quest name is required'
      });
    }
    
    const result = await playerService.recordQuestCompletion(
      steamid, 
      questName, 
      xpReward
    );
    
    res.json({
      success: true,
      data: result,
      message: result.leveledUp
        ? `Quest completed! Leveled up to level ${result.player.level}!`
        : 'Quest completed successfully'
    });
  } catch (error) {
    console.error('Error recording quest completion:', error);
    
    if (error.message === 'Player not found') {
      return res.status(404).json({
        success: false,
        error: 'Player not found'
      });
    }
    
    if (error.message === 'Invalid Steam ID format') {
      return res.status(400).json({
        success: false,
        error: 'Invalid Steam ID format'
      });
    }
    
    if (error.message === 'Quest name is required') {
      return res.status(400).json({
        success: false,
        error: error.message
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Failed to record quest completion'
    });
  }
});

/**
 * GET /api/players/:steamid/matches
 * Get player match history
 */
router.get('/:steamid/matches', async (req, res) => {
  try {
    const { steamid } = req.params;
    const limit = parseInt(req.query.limit) || 20;
    
    if (limit < 1 || limit > 100) {
      return res.status(400).json({
        success: false,
        error: 'Limit must be between 1 and 100'
      });
    }
    
    const matches = await playerService.getPlayerMatches(steamid, limit);
    
    res.json({
      success: true,
      data: matches,
      count: matches.length
    });
  } catch (error) {
    console.error('Error fetching player matches:', error);
    
    if (error.message === 'Invalid Steam ID format') {
      return res.status(400).json({
        success: false,
        error: 'Invalid Steam ID format'
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Failed to fetch player matches'
    });
  }
});

/**
 * GET /api/players/:steamid/xp-progress
 * Get player XP progress information
 */
router.get('/:steamid/xp-progress', async (req, res) => {
  try {
    const { steamid } = req.params;
    const progress = await playerService.getXPProgress(steamid);
    
    res.json({
      success: true,
      data: progress
    });
  } catch (error) {
    console.error('Error fetching XP progress:', error);
    
    if (error.message === 'Player not found') {
      return res.status(404).json({
        success: false,
        error: 'Player not found'
      });
    }
    
    if (error.message === 'Invalid Steam ID format') {
      return res.status(400).json({
        success: false,
        error: 'Invalid Steam ID format'
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Failed to fetch XP progress'
    });
  }
});

/**
 * POST /api/players/calculate-match-xp
 * Calculate XP for a match (utility endpoint)
 */
router.post('/calculate-match-xp', (req, res) => {
  try {
    const matchData = req.body;
    const xpBreakdown = playerService.calculateMatchXP(matchData);
    
    res.json({
      success: true,
      data: xpBreakdown
    });
  } catch (error) {
    console.error('Error calculating match XP:', error);
    
    res.status(400).json({
      success: false,
      error: 'Failed to calculate match XP',
      details: error.message
    });
  }
});

/**
 * GET /api/players/xp-rewards
 * Get XP reward values for different actions
 */
router.get('/xp-rewards', (req, res) => {
  try {
    const { action } = req.query;
    
    if (action) {
      const reward = playerService.getXPReward(action);
      return res.json({
        success: true,
        data: {
          action,
          reward
        }
      });
    }
    
    // Return all XP values
    const xpCalculator = require('../utils/xpCalculator');
    res.json({
      success: true,
      data: xpCalculator.XP_VALUES
    });
  } catch (error) {
    console.error('Error fetching XP rewards:', error);
    
    res.status(500).json({
      success: false,
      error: 'Failed to fetch XP rewards'
    });
  }
});

/**
 * GET /api/players/level-table
 * Get level progression table
 */
router.get('/level-table', (req, res) => {
  try {
    const maxLevel = parseInt(req.query.maxLevel) || 50;
    
    if (maxLevel < 1 || maxLevel > 200) {
      return res.status(400).json({
        success: false,
        error: 'Max level must be between 1 and 200'
      });
    }
    
    const levelTable = playerService.getLevelTable(maxLevel);
    
    res.json({
      success: true,
      data: levelTable,
      count: levelTable.length
    });
  } catch (error) {
    console.error('Error fetching level table:', error);
    
    res.status(500).json({
      success: false,
      error: 'Failed to fetch level table'
    });
  }
});

module.exports = router;
