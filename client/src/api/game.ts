import api from './api';

// Description: Get current game statistics
// Endpoint: GET /api/game/stats
// Request: {}
// Response: { onlinePlayers: number, activeRounds: number, survivorWinRate: number, newPlayersToday: number, avgRoundTime: string, uptime: string }
export const getGameStats = () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        onlinePlayers: 24,
        activeRounds: 3,
        survivorWinRate: 45,
        newPlayersToday: 8,
        avgRoundTime: "4:32",
        uptime: "99.9%"
      });
    }, 500);
  });
  // Uncomment the below lines to make an actual API call
  // try {
  //   return await api.get('/api/game/stats');
  // } catch (error) {
  //   throw new Error(error?.response?.data?.error || error.message);
  // }
}

// Description: Get current match information
// Endpoint: GET /api/game/current-match
// Request: {}
// Response: { roundNumber: number, timeRemaining: string, timeProgress: number, survivors: Array<any>, killer: any }
export const getCurrentMatch = () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        roundNumber: 7,
        timeRemaining: "2:45",
        timeProgress: 54,
        survivors: [
          { name: "PlayerOne", character: "Gordon Freeman" },
          { name: "PlayerTwo", character: "Medic" },
          { name: "PlayerThree", character: "Engineer" }
        ],
        killer: {
          name: "PlayerFour",
          health: 85
        }
      });
    }, 500);
  });
  // Uncomment the below lines to make an actual API call
  // try {
  //   return await api.get('/api/game/current-match');
  // } catch (error) {
  //   throw new Error(error?.response?.data?.error || error.message);
  // }
}