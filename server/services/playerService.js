const Player = require('../models/Player');
const Match = require('../models/Match');
const xpCalculator = require('../utils/xpCalculator');

/**
 * Player Service
 * Handles all player-related business logic
 */
class PlayerService {
  /**
   * Get player profile by Steam ID
   * @param {string} steamId - Steam ID of the player
   * @returns {Promise<Object>} Player profile
   */
  async getPlayerProfile(steamId) {
    if (!steamId || !/^[0-9]{17}$/.test(steamId)) {
      throw new Error('Invalid Steam ID format');
    }

    const player = await Player.findOne({ steamId });
    
    if (!player) {
      throw new Error('Player not found');
    }

    // Update last seen
    await player.updateLastSeen();

    return player;
  }

  /**
   * Update player statistics
   * @param {string} steamId - Steam ID of the player
   * @param {Object} stats - Statistics to update
   * @returns {Promise<Object>} Updated player
   */
  async updatePlayerStats(steamId, stats) {
    if (!steamId || !/^[0-9]{17}$/.test(steamId)) {
      throw new Error('Invalid Steam ID format');
    }

    const player = await Player.findOne({ steamId });
    
    if (!player) {
      throw new Error('Player not found');
    }

    // Update stats incrementally
    if (stats.gamesPlayed !== undefined) {
      player.stats.gamesPlayed += stats.gamesPlayed;
    }
    if (stats.wins !== undefined) {
      player.stats.wins += stats.wins;
    }
    if (stats.losses !== undefined) {
      player.stats.losses += stats.losses;
    }
    if (stats.kills !== undefined) {
      player.stats.kills += stats.kills;
    }
    if (stats.deaths !== undefined) {
      player.stats.deaths += stats.deaths;
    }
    if (stats.totalPlaytime !== undefined) {
      player.stats.totalPlaytime += stats.totalPlaytime;
    }

    // Update favorite character if provided
    if (stats.favoriteCharacter) {
      player.favoriteCharacter = stats.favoriteCharacter;
    }

    await player.save();
    return player;
  }

  /**
   * Add XP to player and update level
   * @param {string} steamId - Steam ID of the player
   * @param {number} xpAmount - Amount of XP to add
   * @param {string} reason - Reason for XP gain (optional)
   * @returns {Promise<Object>} Updated player with XP details
   */
  async addPlayerXP(steamId, xpAmount, reason = 'Unknown') {
    if (!steamId || !/^[0-9]{17}$/.test(steamId)) {
      throw new Error('Invalid Steam ID format');
    }

    if (typeof xpAmount !== 'number' || xpAmount < 0) {
      throw new Error('XP amount must be a positive number');
    }

    const player = await Player.findOne({ steamId });
    
    if (!player) {
      throw new Error('Player not found');
    }

    const oldLevel = player.level;
    const oldXP = player.xp;

    // Add XP and update level
    await player.addXP(xpAmount);

    const leveledUp = player.level > oldLevel;

    return {
      player,
      xpAdded: xpAmount,
      oldXP,
      newXP: player.xp,
      oldLevel,
      newLevel: player.level,
      leveledUp,
      reason
    };
  }

  /**
   * Record quest completion for player
   * @param {string} steamId - Steam ID of the player
   * @param {string} questName - Name of the completed quest
   * @param {number} xpReward - XP reward for quest (default: 50)
   * @returns {Promise<Object>} Updated player
   */
  async recordQuestCompletion(steamId, questName, xpReward = 50) {
    if (!steamId || !/^[0-9]{17}$/.test(steamId)) {
      throw new Error('Invalid Steam ID format');
    }

    if (!questName || typeof questName !== 'string') {
      throw new Error('Quest name is required');
    }

    const player = await Player.findOne({ steamId });
    
    if (!player) {
      throw new Error('Player not found');
    }

    // Increment quests completed
    player.stats.questsCompleted += 1;

    // Add quest to achievements if not already present
    const achievementName = `quest_${questName}`;
    if (!player.achievements.includes(achievementName)) {
      player.achievements.push(achievementName);
    }

    await player.save();

    // Add XP reward
    const xpResult = await this.addPlayerXP(steamId, xpReward, `Quest: ${questName}`);

    return {
      player: xpResult.player,
      questName,
      xpReward,
      leveledUp: xpResult.leveledUp
    };
  }

  /**
   * Get player match history
   * @param {string} steamId - Steam ID of the player
   * @param {number} limit - Maximum number of matches to return (default: 20)
   * @returns {Promise<Array>} Array of matches
   */
  async getPlayerMatches(steamId, limit = 20) {
    if (!steamId || !/^[0-9]{17}$/.test(steamId)) {
      throw new Error('Invalid Steam ID format');
    }

    const matches = await Match.getPlayerMatches(steamId, limit);

    // Transform matches to include player-specific data
    return matches.map(match => {
      const playerData = match.players.find(p => p.steamId === steamId);
      
      return {
        matchId: match.matchId,
        mapName: match.mapName,
        winner: match.winner,
        duration: match.duration,
        startedAt: match.startedAt,
        endedAt: match.endedAt,
        playerStats: playerData ? {
          team: playerData.team,
          character: playerData.character,
          kills: playerData.kills,
          deaths: playerData.deaths,
          xpEarned: playerData.xpEarned,
          questsCompleted: playerData.questsCompleted
        } : null
      };
    });
  }

  /**
   * Get leaderboard
   * @param {string} sortBy - Field to sort by (xp, wins, kills)
   * @param {number} limit - Maximum number of players to return (default: 100)
   * @returns {Promise<Array>} Array of top players
   */
  async getLeaderboard(sortBy = 'xp', limit = 100) {
    const validSortFields = ['xp', 'wins', 'kills'];
    
    if (!validSortFields.includes(sortBy)) {
      throw new Error(`Invalid sort field. Must be one of: ${validSortFields.join(', ')}`);
    }

    if (typeof limit !== 'number' || limit < 1 || limit > 1000) {
      throw new Error('Limit must be between 1 and 1000');
    }

    let sortOptions = {};
    
    if (sortBy === 'xp') {
      sortOptions = { xp: -1 };
    } else if (sortBy === 'wins') {
      sortOptions = { 'stats.wins': -1 };
    } else if (sortBy === 'kills') {
      sortOptions = { 'stats.kills': -1 };
    }

    const players = await Player.find()
      .sort(sortOptions)
      .limit(limit)
      .select('steamId username avatar level xp stats');

    // Add rank to each player
    return players.map((player, index) => ({
      rank: index + 1,
      steamId: player.steamId,
      username: player.username,
      avatar: player.avatar,
      level: player.level,
      xp: player.xp,
      stats: player.stats,
      winRate: player.winRate,
      kdRatio: player.kdRatio
    }));
  }

  /**
   * Calculate XP for a match
   * @param {Object} matchData - Match data including result, kills, survival time, etc.
   * @returns {Object} XP breakdown
   */
  calculateMatchXP(matchData) {
    return xpCalculator.calculateMatchXP(matchData);
  }

  /**
   * Get XP reward for a specific action
   * @param {string} action - Action name
   * @returns {number} XP reward amount
   */
  getXPReward(action) {
    return xpCalculator.getXPReward(action);
  }

  /**
   * Get XP progress information for a player
   * @param {string} steamId - Steam ID of the player
   * @returns {Promise<Object>} XP progress details
   */
  async getXPProgress(steamId) {
    if (!steamId || !/^[0-9]{17}$/.test(steamId)) {
      throw new Error('Invalid Steam ID format');
    }

    const player = await Player.findOne({ steamId });
    
    if (!player) {
      throw new Error('Player not found');
    }

    return xpCalculator.xpProgress(player.xp);
  }

  /**
   * Get level progression table
   * @param {number} maxLevel - Maximum level to calculate (default: 50)
   * @returns {Array} Level progression table
   */
  getLevelTable(maxLevel = 50) {
    return xpCalculator.getLevelTable(maxLevel);
  }
}


module.exports = new PlayerService();
