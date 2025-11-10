const express = require('express');
const router = express.Router();
const Match = require('../models/Match');
const gameServerService = require('../services/gameServerService');

/**
 * Middleware to validate API key for game server requests
 */
const validateAPIKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  
  if (!gameServerService.validateAPIKey(apiKey)) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid or missing API key'
    });
  }
  
  next();
};

/**
 * POST /api/matches
 * Create a new match record
 * Requires API key authentication
 */
router.post('/', validateAPIKey, async (req, res) => {
  try {
    const matchData = req.body;

    // Validate required fields
    if (!matchData.matchId) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'matchId is required'
      });
    }

    if (!matchData.mapName) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'mapName is required'
      });
    }

    if (!matchData.winner) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'winner is required'
      });
    }

    if (!matchData.players || !Array.isArray(matchData.players)) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'players array is required'
      });
    }

    // Record match and update player stats
    const match = await gameServerService.recordMatch(matchData);

    res.status(201).json({
      success: true,
      message: 'Match recorded successfully',
      match: match.getSummary()
    });
  } catch (error) {
    console.error('Error creating match:', error);
    
    if (error.message.includes('Missing required')) {
      return res.status(400).json({
        error: 'Validation Error',
        message: error.message
      });
    }

    if (error.code === 11000) {
      return res.status(409).json({
        error: 'Conflict',
        message: 'Match with this ID already exists'
      });
    }

    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to record match'
    });
  }
});

/**
 * GET /api/matches/:matchid
 * Get details of a specific match
 */
router.get('/:matchid', async (req, res) => {
  try {
    const { matchid } = req.params;

    const match = await Match.findOne({ matchId: matchid });

    if (!match) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Match not found'
      });
    }

    res.json({
      success: true,
      match
    });
  } catch (error) {
    console.error('Error fetching match:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch match'
    });
  }
});

/**
 * GET /api/matches
 * Get list of recent matches
 * Query params:
 *   - limit: number of matches to return (default: 10, max: 100)
 *   - steamId: filter by player Steam ID
 */
router.get('/', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 10, 100);
    const { steamId } = req.query;

    let matches;

    if (steamId) {
      // Get matches for specific player
      matches = await Match.getPlayerMatches(steamId, limit);
    } else {
      // Get recent matches
      matches = await Match.getRecentMatches(limit);
    }

    res.json({
      success: true,
      count: matches.length,
      matches
    });
  } catch (error) {
    console.error('Error fetching matches:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch matches'
    });
  }
});

module.exports = router;
