const express = require('express');
const router = express.Router();
const gameServerService = require('../services/gameServerService');

// In-memory storage for server status (in production, this could be Redis or database)
let serverStatus = {
  online: false,
  playerCount: 0,
  maxPlayers: 24,
  mapName: 'Unknown',
  gameState: 'LOBBY',
  uptime: 0,
  activePlayers: [],
  lastUpdate: null
};

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
 * Middleware to check if user is admin
 * In production, this should check against a proper admin system
 */
const requireAdmin = (req, res, next) => {
  // Check if user is authenticated and is admin
  if (!req.session || !req.session.user) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Authentication required'
    });
  }

  // In production, check if user has admin role
  // For now, we'll use a simple check (you should implement proper admin checking)
  const adminSteamIds = (process.env.ADMIN_STEAM_IDS || '').split(',');
  
  if (!adminSteamIds.includes(req.session.user.steamId)) {
    return res.status(403).json({
      error: 'Forbidden',
      message: 'Admin access required'
    });
  }

  next();
};

/**
 * POST /api/server/status
 * Update server status (called by game server)
 * Requires API key authentication
 */
router.post('/status', validateAPIKey, async (req, res) => {
  try {
    const statusUpdate = req.body;

    // Update server status
    serverStatus = {
      online: statusUpdate.online !== undefined ? statusUpdate.online : true,
      playerCount: statusUpdate.playerCount || 0,
      maxPlayers: statusUpdate.maxPlayers || 24,
      mapName: statusUpdate.mapName || serverStatus.mapName,
      gameState: statusUpdate.gameState || serverStatus.gameState,
      uptime: statusUpdate.uptime || 0,
      activePlayers: statusUpdate.activePlayers || [],
      lastUpdate: new Date()
    };

    res.json({
      success: true,
      message: 'Server status updated'
    });
  } catch (error) {
    console.error('Error updating server status:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to update server status'
    });
  }
});

/**
 * GET /api/server/status
 * Get current server status
 */
router.get('/status', async (req, res) => {
  try {
    // Check if status is stale (no update in last 60 seconds)
    const isStale = serverStatus.lastUpdate && 
                    (Date.now() - new Date(serverStatus.lastUpdate).getTime()) > 60000;

    res.json({
      success: true,
      status: {
        ...serverStatus,
        online: isStale ? false : serverStatus.online
      }
    });
  } catch (error) {
    console.error('Error fetching server status:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch server status'
    });
  }
});

/**
 * POST /api/server/command
 * Send command to game server (admin only)
 * This is a placeholder - actual implementation would need a way to communicate with game server
 */
router.post('/command', requireAdmin, async (req, res) => {
  try {
    const { command, parameters } = req.body;

    if (!command) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'command is required'
      });
    }

    // Validate allowed commands
    const allowedCommands = ['restart_round', 'change_map', 'kick_player', 'end_match'];
    
    if (!allowedCommands.includes(command)) {
      return res.status(400).json({
        error: 'Validation Error',
        message: `Invalid command. Allowed commands: ${allowedCommands.join(', ')}`
      });
    }

    // Log the command
    console.log(`Admin command received: ${command}`, parameters);

    // In a real implementation, you would:
    // 1. Store the command in a queue/database
    // 2. Have the game server poll for commands
    // 3. Or use WebSockets/Server-Sent Events to push commands
    
    // For now, we'll just acknowledge the command
    res.json({
      success: true,
      message: `Command '${command}' queued for execution`,
      command,
      parameters,
      timestamp: new Date()
    });
  } catch (error) {
    console.error('Error processing server command:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to process command'
    });
  }
});

/**
 * GET /api/server/info
 * Get general server information
 */
router.get('/info', async (req, res) => {
  try {
    res.json({
      success: true,
      info: {
        name: process.env.SERVER_NAME || 'GModsaken Server',
        version: process.env.SERVER_VERSION || '1.0.0',
        gamemode: 'GModsaken',
        maxPlayers: serverStatus.maxPlayers,
        currentMap: serverStatus.mapName
      }
    });
  } catch (error) {
    console.error('Error fetching server info:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to fetch server info'
    });
  }
});

module.exports = router;
