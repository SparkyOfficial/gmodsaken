/**
 * XP Calculator Utility
 * Provides XP calculation and leveling logic for the GModsaken gamemode
 */

/**
 * Base XP values for different actions
 */
const XP_VALUES = {
  // Match results
  MATCH_WIN: 100,
  MATCH_LOSS: 25,
  MATCH_DRAW: 50,
  
  // Combat
  KILL: 10,
  ASSIST: 5,
  
  // Objectives
  QUEST_COMPLETE: 50,
  QUEST_ITEM_FOUND: 15,
  
  // Survival
  SURVIVAL_TIME: 1, // per minute
  ESCAPE_SUCCESS: 75,
  
  // Team play
  REVIVE_TEAMMATE: 20,
  HEAL_TEAMMATE: 10,
  
  // Special achievements
  FIRST_BLOOD: 15,
  KILLING_SPREE: 25,
  NO_DEATH_WIN: 50
};

/**
 * Calculate level from XP
 * Formula: Level = floor(sqrt(XP / 100))
 * 
 * @param {number} xp - Total XP amount
 * @returns {number} Player level
 */
function calculateLevel(xp) {
  if (typeof xp !== 'number' || xp < 0) {
    throw new Error('XP must be a non-negative number');
  }
  
  return Math.floor(Math.sqrt(xp / 100));
}

/**
 * Calculate XP required for a specific level
 * Formula: XP = Level^2 * 100
 * 
 * @param {number} level - Target level
 * @returns {number} Total XP required for that level
 */
function xpForLevel(level) {
  if (typeof level !== 'number' || level < 1) {
    throw new Error('Level must be a positive number');
  }
  
  return Math.pow(level, 2) * 100;
}

/**
 * Calculate XP required for next level from current XP
 * 
 * @param {number} currentXP - Current XP amount
 * @returns {number} Total XP required for next level
 */
function xpForNextLevel(currentXP) {
  const currentLevel = calculateLevel(currentXP);
  return xpForLevel(currentLevel + 1);
}

/**
 * Calculate XP remaining until next level
 * 
 * @param {number} currentXP - Current XP amount
 * @returns {Object} Object with current level, next level XP, and remaining XP
 */
function xpProgress(currentXP) {
  const currentLevel = calculateLevel(currentXP);
  const currentLevelXP = xpForLevel(currentLevel);
  const nextLevelXP = xpForLevel(currentLevel + 1);
  const xpIntoLevel = currentXP - currentLevelXP;
  const xpNeededForLevel = nextLevelXP - currentLevelXP;
  const progressPercent = (xpIntoLevel / xpNeededForLevel) * 100;
  
  return {
    currentLevel,
    currentXP,
    currentLevelXP,
    nextLevelXP,
    xpIntoLevel,
    xpNeededForLevel,
    xpRemaining: xpNeededForLevel - xpIntoLevel,
    progressPercent: Math.min(100, Math.max(0, progressPercent))
  };
}

/**
 * Calculate XP reward for match completion
 * 
 * @param {Object} matchData - Match data
 * @param {string} matchData.result - Match result (WIN/LOSS/DRAW)
 * @param {number} matchData.kills - Number of kills
 * @param {number} matchData.deaths - Number of deaths
 * @param {number} matchData.survivalTime - Survival time in seconds
 * @param {number} matchData.questsCompleted - Number of quests completed
 * @param {boolean} matchData.escaped - Whether player escaped (for survivors)
 * @param {Object} matchData.bonuses - Additional bonuses
 * @returns {Object} XP breakdown
 */
function calculateMatchXP(matchData) {
  const {
    result = 'LOSS',
    kills = 0,
    deaths = 0,
    survivalTime = 0,
    questsCompleted = 0,
    escaped = false,
    bonuses = {}
  } = matchData;
  
  const breakdown = {
    base: 0,
    kills: 0,
    survival: 0,
    quests: 0,
    bonuses: 0,
    total: 0
  };
  
  // Base XP for match result
  if (result === 'WIN') {
    breakdown.base = XP_VALUES.MATCH_WIN;
  } else if (result === 'LOSS') {
    breakdown.base = XP_VALUES.MATCH_LOSS;
  } else if (result === 'DRAW') {
    breakdown.base = XP_VALUES.MATCH_DRAW;
  }
  
  // XP for kills
  breakdown.kills = kills * XP_VALUES.KILL;
  
  // XP for survival time (per minute)
  const survivalMinutes = Math.floor(survivalTime / 60);
  breakdown.survival = survivalMinutes * XP_VALUES.SURVIVAL_TIME;
  
  // XP for quests
  breakdown.quests = questsCompleted * XP_VALUES.QUEST_COMPLETE;
  
  // Bonus XP
  if (escaped) {
    breakdown.bonuses += XP_VALUES.ESCAPE_SUCCESS;
  }
  
  if (bonuses.firstBlood) {
    breakdown.bonuses += XP_VALUES.FIRST_BLOOD;
  }
  
  if (bonuses.killingSpree) {
    breakdown.bonuses += XP_VALUES.KILLING_SPREE;
  }
  
  if (bonuses.noDeathWin && deaths === 0 && result === 'WIN') {
    breakdown.bonuses += XP_VALUES.NO_DEATH_WIN;
  }
  
  // Calculate total
  breakdown.total = breakdown.base + breakdown.kills + breakdown.survival + 
                    breakdown.quests + breakdown.bonuses;
  
  return breakdown;
}

/**
 * Get XP reward for a specific action
 * 
 * @param {string} action - Action name (e.g., 'KILL', 'QUEST_COMPLETE')
 * @returns {number} XP reward amount
 */
function getXPReward(action) {
  const upperAction = action.toUpperCase();
  
  if (XP_VALUES.hasOwnProperty(upperAction)) {
    return XP_VALUES[upperAction];
  }
  
  console.warn(`Unknown XP action: ${action}`);
  return 0;
}

/**
 * Calculate level progression table
 * 
 * @param {number} maxLevel - Maximum level to calculate
 * @returns {Array} Array of level progression data
 */
function getLevelTable(maxLevel = 50) {
  const table = [];
  
  for (let level = 1; level <= maxLevel; level++) {
    const xpRequired = xpForLevel(level);
    const xpForNext = level < maxLevel ? xpForLevel(level + 1) : null;
    const xpNeeded = xpForNext ? xpForNext - xpRequired : null;
    
    table.push({
      level,
      xpRequired,
      xpForNext,
      xpNeeded
    });
  }
  
  return table;
}

module.exports = {
  XP_VALUES,
  calculateLevel,
  xpForLevel,
  xpForNextLevel,
  xpProgress,
  calculateMatchXP,
  getXPReward,
  getLevelTable
};
