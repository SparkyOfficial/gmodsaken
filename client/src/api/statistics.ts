import api from './api';

// Description: Get game statistics
// Endpoint: GET /api/statistics/overview
// Request: {}
// Response: { overview: any, trends: Array<any>, activity: Array<any>, characters: Array<any> }
export const getStatistics = () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        overview: {
          totalRounds: 1247,
          roundsToday: 43,
          survivorWinRate: 45,
          killerWinRate: 55,
          avgRoundTime: "4:32",
          trend: "↗ improving"
        },
        trends: [
          {
            period: "This Week",
            change: +3,
            survivorWinRate: 48,
            killerWinRate: 52
          },
          {
            period: "Last Week",
            change: -2,
            survivorWinRate: 45,
            killerWinRate: 55
          },
          {
            period: "This Month",
            change: +1,
            survivorWinRate: 46,
            killerWinRate: 54
          }
        ],
        activity: [
          {
            timeRange: "00:00 - 06:00",
            avgPlayers: 8,
            peakPlayers: 15,
            activityLevel: 25,
            roundsPlayed: 12
          },
          {
            timeRange: "06:00 - 12:00",
            avgPlayers: 18,
            peakPlayers: 28,
            activityLevel: 60,
            roundsPlayed: 34
          },
          {
            timeRange: "12:00 - 18:00",
            avgPlayers: 24,
            peakPlayers: 32,
            activityLevel: 85,
            roundsPlayed: 48
          },
          {
            timeRange: "18:00 - 24:00",
            avgPlayers: 28,
            peakPlayers: 35,
            activityLevel: 100,
            roundsPlayed: 52
          }
        ],
        characters: [
          {
            name: "Gordon Freeman",
            role: "Survivor",
            timesPlayed: 342,
            winRate: 52,
            avgSurvivalTime: "3:45",
            pickRate: 28,
            popularity: "High"
          },
          {
            name: "Rebel",
            role: "Survivor",
            timesPlayed: 298,
            winRate: 48,
            avgSurvivalTime: "3:12",
            pickRate: 24,
            popularity: "High"
          },
          {
            name: "Medic",
            role: "Survivor",
            timesPlayed: 267,
            winRate: 58,
            avgSurvivalTime: "4:23",
            pickRate: 22,
            popularity: "High"
          },
          {
            name: "Engineer",
            role: "Survivor",
            timesPlayed: 189,
            winRate: 44,
            avgSurvivalTime: "2:58",
            pickRate: 15,
            popularity: "Medium"
          },
          {
            name: "Security Guard",
            role: "Survivor",
            timesPlayed: 156,
            winRate: 50,
            avgSurvivalTime: "3:34",
            pickRate: 13,
            popularity: "Medium"
          },
          {
            name: "Mayor",
            role: "Survivor",
            timesPlayed: 123,
            winRate: 62,
            avgSurvivalTime: "4:45",
            pickRate: 10,
            popularity: "Low"
          },
          {
            name: "The Flesh",
            role: "Killer",
            timesPlayed: 1247,
            winRate: 55,
            avgSurvivalTime: "N/A",
            pickRate: 100,
            popularity: "High"
          }
        ]
      });
    }, 500);
  });
  // Uncomment the below lines to make an actual API call
  // try {
  //   return await api.get('/api/statistics/overview');
  // } catch (error) {
  //   throw new Error(error?.response?.data?.error || error.message);
  // }
}

// Description: Get leaderboard data
// Endpoint: GET /api/statistics/leaderboard
// Request: {}
// Response: { survivors: Array<any>, killers: Array<any> }
export const getLeaderboard = () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        survivors: [
          { name: "SurvivalKing", winRate: 78, roundsPlayed: 234 },
          { name: "MedicMain", winRate: 74, roundsPlayed: 189 },
          { name: "TeamPlayer", winRate: 71, roundsPlayed: 156 },
          { name: "GordonExpert", winRate: 68, roundsPlayed: 298 },
          { name: "LastStanding", winRate: 66, roundsPlayed: 203 },
          { name: "Strategist", winRate: 64, roundsPlayed: 145 },
          { name: "QuickEscape", winRate: 62, roundsPlayed: 167 },
          { name: "TeamMedic", winRate: 61, roundsPlayed: 178 }
        ],
        killers: [
          { name: "FleshMaster", winRate: 82, roundsPlayed: 298 },
          { name: "Hunter", winRate: 79, roundsPlayed: 234 },
          { name: "Predator", winRate: 76, roundsPlayed: 187 },
          { name: "Nightmare", winRate: 74, roundsPlayed: 203 },
          { name: "Stalker", winRate: 71, roundsPlayed: 156 },
          { name: "DeathBringer", winRate: 69, roundsPlayed: 189 },
          { name: "ShadowKiller", winRate: 67, roundsPlayed: 145 },
          { name: "TheHunt", winRate: 65, roundsPlayed: 167 }
        ]
      });
    }, 500);
  });
  // Uncomment the below lines to make an actual API call
  // try {
  //   return await api.get('/api/statistics/leaderboard');
  // } catch (error) {
  //   throw new Error(error?.response?.data?.error || error.message);
  // }
}

// Description: Get recent match data
// Endpoint: GET /api/statistics/recent-matches
// Request: {}
// Response: { matches: Array<any> }
export const getRecentMatches = () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        matches: [
          {
            winner: "survivors",
            duration: "5:43",
            timeAgo: "2 minutes ago",
            survivors: [
              { name: "PlayerOne", character: "Gordon Freeman" },
              { name: "PlayerTwo", character: "Medic" }
            ],
            killer: { name: "PlayerThree", kills: 4 }
          },
          {
            winner: "killer",
            duration: "3:21",
            timeAgo: "8 minutes ago",
            survivors: [
              { name: "PlayerFour", character: "Rebel" },
              { name: "PlayerFive", character: "Engineer" },
              { name: "PlayerSix", character: "Security Guard" }
            ],
            killer: { name: "PlayerSeven", kills: 6 }
          },
          {
            winner: "survivors",
            duration: "6:00",
            timeAgo: "15 minutes ago",
            survivors: [
              { name: "PlayerEight", character: "Mayor" },
              { name: "PlayerNine", character: "Medic" },
              { name: "PlayerTen", character: "Gordon Freeman" }
            ],
            killer: { name: "PlayerEleven", kills: 3 }
          },
          {
            winner: "killer",
            duration: "2:45",
            timeAgo: "23 minutes ago",
            survivors: [
              { name: "PlayerTwelve", character: "Rebel" },
              { name: "PlayerThirteen", character: "Engineer" }
            ],
            killer: { name: "PlayerFourteen", kills: 5 }
          },
          {
            winner: "survivors",
            duration: "4:32",
            timeAgo: "31 minutes ago",
            survivors: [
              { name: "PlayerFifteen", character: "Security Guard" },
              { name: "PlayerSixteen", character: "Medic" },
              { name: "PlayerSeventeen", character: "Gordon Freeman" },
              { name: "PlayerEighteen", character: "Mayor" }
            ],
            killer: { name: "PlayerNineteen", kills: 2 }
          }
        ]
      });
    }, 500);
  });
  // Uncomment the below lines to make an actual API call
  // try {
  //   return await api.get('/api/statistics/recent-matches');
  // } catch (error) {
  //   throw new Error(error?.response?.data?.error || error.message);
  // }
}