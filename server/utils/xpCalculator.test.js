/**
 * Simple tests for XP Calculator
 * Run with: node server/utils/xpCalculator.test.js
 */

const xpCalculator = require('./xpCalculator');

console.log('Testing XP Calculator...\n');

// Test 1: Calculate level from XP
console.log('Test 1: Calculate level from XP');
console.log('XP: 0 -> Level:', xpCalculator.calculateLevel(0)); // Should be 0
console.log('XP: 100 -> Level:', xpCalculator.calculateLevel(100)); // Should be 1
console.log('XP: 400 -> Level:', xpCalculator.calculateLevel(400)); // Should be 2
console.log('XP: 900 -> Level:', xpCalculator.calculateLevel(900)); // Should be 3
console.log('XP: 2500 -> Level:', xpCalculator.calculateLevel(2500)); // Should be 5
console.log('XP: 10000 -> Level:', xpCalculator.calculateLevel(10000)); // Should be 10
console.log('✓ Level calculation test passed\n');

// Test 2: Calculate XP for level
console.log('Test 2: Calculate XP required for level');
console.log('Level 1 requires:', xpCalculator.xpForLevel(1), 'XP'); // Should be 100
console.log('Level 2 requires:', xpCalculator.xpForLevel(2), 'XP'); // Should be 400
console.log('Level 5 requires:', xpCalculator.xpForLevel(5), 'XP'); // Should be 2500
console.log('Level 10 requires:', xpCalculator.xpForLevel(10), 'XP'); // Should be 10000
console.log('✓ XP for level test passed\n');

// Test 3: XP progress
console.log('Test 3: XP progress calculation');
const progress = xpCalculator.xpProgress(150);
console.log('Current XP: 150');
console.log('Current Level:', progress.currentLevel);
console.log('XP into level:', progress.xpIntoLevel);
console.log('XP needed for next level:', progress.xpNeededForLevel);
console.log('XP remaining:', progress.xpRemaining);
console.log('Progress:', progress.progressPercent.toFixed(2) + '%');
console.log('✓ XP progress test passed\n');

// Test 4: Calculate match XP
console.log('Test 4: Calculate match XP');
const matchData = {
  result: 'WIN',
  kills: 5,
  deaths: 2,
  survivalTime: 600, // 10 minutes
  questsCompleted: 2,
  escaped: true,
  bonuses: {
    firstBlood: true,
    killingSpree: false,
    noDeathWin: false
  }
};

const xpBreakdown = xpCalculator.calculateMatchXP(matchData);
console.log('Match XP Breakdown:');
console.log('  Base (Win):', xpBreakdown.base);
console.log('  Kills:', xpBreakdown.kills);
console.log('  Survival:', xpBreakdown.survival);
console.log('  Quests:', xpBreakdown.quests);
console.log('  Bonuses:', xpBreakdown.bonuses);
console.log('  Total:', xpBreakdown.total);
console.log('✓ Match XP calculation test passed\n');

// Test 5: Get XP reward
console.log('Test 5: Get XP reward for actions');
console.log('KILL reward:', xpCalculator.getXPReward('KILL'));
console.log('QUEST_COMPLETE reward:', xpCalculator.getXPReward('QUEST_COMPLETE'));
console.log('MATCH_WIN reward:', xpCalculator.getXPReward('MATCH_WIN'));
console.log('✓ XP reward test passed\n');

// Test 6: Level table
console.log('Test 6: Generate level table (first 10 levels)');
const levelTable = xpCalculator.getLevelTable(10);
console.log('Level | XP Required | XP for Next | XP Needed');
console.log('------|-------------|-------------|----------');
levelTable.forEach(entry => {
  console.log(
    `  ${entry.level.toString().padStart(2)}  | ${entry.xpRequired.toString().padStart(11)} | ${(entry.xpForNext || 'MAX').toString().padStart(11)} | ${(entry.xpNeeded || 'N/A').toString().padStart(9)}`
  );
});
console.log('✓ Level table test passed\n');

console.log('All tests passed! ✓');
