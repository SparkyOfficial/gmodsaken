const Player = require('../models/Player');
const Match = require('../models/Match');
const { calculateXP } = require('../utils/xpCalculator');

class GameServerService {
  /**
   * Validate API key from game server
   * @param {string} apiKey - API key from request header
   * @returns {boolean} - True if valid, false otherwise
   */
  validateAPIKey(apiKey) {
    if (!apiKey) {
      return false;
    }
    
    const validKey = process.env.GAME_SERVER_API_KEY;
    if (!validKey) {
      console.error('GAME_SERVER_API_KEY not configured in environment');
      return false;
    }
    
    return apiKey === validKey;
  }

  /**
   * Record match results from game server
   * @param {Object} matchData - Match data from game server
   * @returns {Promise<Object>} - Created match document
   */
  async recordMatch(matchData) {
    try {
      // Validate required fields
      if (!matchData.matchId || !matchData.mapName || !matchData.winner || 
          matchData.duration === undefined || !matchData.players || !matchData.startedAt) {
        throw new Error('Missing required match data fields');
      }

      // Create match record
      const match = new Match({
        matchId: matchData.matchId,
        mapName: matchData.mapName,
        gameState: matchData.gameState || 'ENDING',
        winner: matchData.winner,
        duration: matchData.duration,
        players: matchData.players,
        startedAt: new Date(matchData.startedAt),
        endedAt: matchData.endedAt ? new Date(matchData.endedAt) : new Date()
      });

      await match.save();

      // Update player statistics for each player in the match
      const updatePromises = matchData.players.map(async (playerData) => {
        const isWinner = (playerData.team === 'SURVIVOR' && matchData.winner === 'SURVIVORS') ||
                        (playerData.team === 'KILLER' && matchData.winner === 'KILLER');

        // Find or create player
        let player = await Player.findOne({ steamId: playerData.steamId });
        
        if (!player) {
          // Create basic player profile if doesn't exist
          player = new Player({
            steamId: playerData.steamId,
            username: playerData.username || `Player_${playerData.steamId.slice(-4)}`,
            avatar: playerData.avatar || 'https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/fe/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_full.jpg'
          });
        }

        // Update stats
        player.stats.gamesPlayed += 1;
        if (isWinner) {
          player.stats.wins += 1;
        } else {
          player.stats.losses += 1;
        }
        player.stats.kills += playerData.kills || 0;
        player.stats.deaths += playerData.deaths || 0;
        player.stats.questsCompleted += (playerData.questsCompleted || []).length;
        player.stats.totalPlaytime += matchData.duration;

        // Add XP
        if (playerData.xpEarned) {
          await player.addXP(playerData.xpEarned);
        }

        // Update favorite character (most played)
        if (playerData.character) {
          player.favoriteCharacter = playerData.character;
        }

        // Update last seen
        player.lastSeen = new Date();

        await player.save();
      });

      await Promise.all(updatePromises);

      return match;
    } catch (error) {
      console.error('Error recording match:', error);
      throw error;
    }
  }

  /**
   * Update player XP
   * @param {string} steamId - Player's Steam ID
   * @param {number} xp - XP amount to add
   * @param {string} reason - Reason for XP gain
   * @returns {Promise<Object>} - Updated player document
   */
  async updatePlayerXP(steamId, xp, reason) {
    try {
      if (!steamId || xp === undefined) {
        throw new Error('Missing required parameters: steamId and xp');
      }

      if (typeof xp !== 'number' || xp < 0) {
        throw new Error('XP must be a positive number');
      }

      // Find player
      const player = await Player.findOne({ steamId });
      
      if (!player) {
        throw new Error(`Player with Steam ID ${steamId} not found`);
      }

      // Add XP and update level
      await player.addXP(xp);

      console.log(`Added ${xp} XP to player ${steamId} (${reason}). New total: ${player.xp}`);

      return player;
    } catch (error) {
      console.error('Error updating player XP:', error);
      throw error;
    }
  }

  /**
   * Record quest completion
   * @param {string} steamId - Player's Steam ID
   * @param {string} questName - Name of completed quest
   * @returns {Promise<Object>} - Updated player document
   */
  async recordQuest(steamId, questName) {
    try {
      if (!steamId || !questName) {
        throw new Error('Missing required parameters: steamId and questName');
      }

      // Find player
      const player = await Player.findOne({ steamId });
      
      if (!player) {
        throw new Error(`Player with Steam ID ${steamId} not found`);
      }

      // Update quest count
      player.stats.questsCompleted += 1;

      // Add achievement if not already unlocked
      const achievementName = `quest_${questName.toLowerCase().replace(/\s+/g, '_')}`;
      if (!player.achievements.includes(achievementName)) {
        player.achievements.push(achievementName);
      }

      // Award XP for quest completion
      const questXP = calculateXP('QUEST_COMPLETE');
      await player.addXP(questXP);

      await player.save();

      console.log(`Player ${steamId} completed quest: ${questName}`);

      return player;
    } catch (error) {
      console.error('Error recording quest:', error);
      throw error;
    }
  }

  /**
   * Get player profile
   * @param {string} steamId - Player's Steam ID
   * @returns {Promise<Object>} - Player document
   */
  async getPlayerProfile(steamId) {
    try {
      if (!steamId) {
        throw new Error('Missing required parameter: steamId');
      }

      const player = await Player.findOne({ steamId });
      
      if (!player) {
        throw new Error(`Player with Steam ID ${steamId} not found`);
      }

      return player;
    } catch (error) {
      console.error('Error fetching player profile:', error);
      throw error;
    }
  }
}

module.exports = new GameServerService();
