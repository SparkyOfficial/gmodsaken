import api from './api';

// Description: Get all character information
// Endpoint: GET /api/characters
// Request: {}
// Response: { characters: Array<any> }
export const getCharacters = () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        characters: [
          {
            name: "Gordon Freeman",
            role: "Survivor",
            description: "Most durable character with crowbar weapon",
            health: 100,
            armor: 100,
            equipment: ["Crowbar"],
            abilities: [
              { name: "Crowbar Strike", description: "Slows The Flesh when hit" },
              { name: "High Durability", description: "Extra armor for survivability" }
            ]
          },
          {
            name: "Rebel",
            role: "Survivor",
            description: "Balanced fighter with pistol weapon",
            health: 100,
            armor: 0,
            equipment: ["Pistol"],
            abilities: [
              { name: "Pistol Shot", description: "Slows The Flesh but may jam" },
              { name: "Balanced Stats", description: "Good for solo and team play" }
            ]
          },
          {
            name: "Medic",
            role: "Survivor",
            description: "Support character with healing abilities",
            health: 100,
            armor: 0,
            equipment: ["Medical Kit"],
            abilities: [
              { name: "Healing", description: "Heal self and teammates 10 HP every 3 seconds" },
              { name: "Team Support", description: "Essential for team survival" }
            ]
          },
          {
            name: "Engineer",
            role: "Survivor",
            description: "Builder class with construction abilities",
            health: 100,
            armor: 10,
            equipment: ["Wrench", "Building Tool"],
            abilities: [
              { name: "Turret", description: "Construct defensive turrets" },
              { name: "Dispenser", description: "Build supply dispensers" },
              { name: "Teleporter", description: "Create teleporter entrances/exits" }
            ]
          },
          {
            name: "Security Guard",
            role: "Survivor",
            description: "Defensive specialist with club weapon",
            health: 100,
            armor: 10,
            equipment: ["Club"],
            abilities: [
              { name: "Club Strike", description: "Causes 5-second white screen effect on The Flesh" },
              { name: "Stamina System", description: "Each swing consumes 35 stamina" }
            ]
          },
          {
            name: "Mayor",
            role: "Survivor",
            description: "Team coordinator with communication tools",
            health: 100,
            armor: 0,
            equipment: ["Phone"],
            abilities: [
              { name: "Phone Communication", description: "Long-distance team communication" },
              { name: "Location Tracking", description: "Track teammate locations" },
              { name: "Armor Aura", description: "Gives nearby allies +1 armor per second" }
            ]
          },
          {
            name: "The Flesh",
            role: "Killer",
            description: "Powerful killer with massive health pool",
            health: 3000,
            armor: 0,
            equipment: ["Axe"],
            abilities: [
              { name: "Axe Attack", description: "Primary close combat weapon" },
              { name: "Headcrab Mutation", description: "Spawns 3 fast headcrabs as temporary allies" },
              { name: "Eye Laser", description: "Powerful ranged attack requiring standing still" }
            ]
          }
        ]
      });
    }, 500);
  });
  // Uncomment the below lines to make an actual API call
  // try {
  //   return await api.get('/api/characters');
  // } catch (error) {
  //   throw new Error(error?.response?.data?.error || error.message);
  // }
}

// Description: Get character statistics
// Endpoint: GET /api/characters/stats
// Request: {}
// Response: { [characterName]: { winRate: number } }
export const getCharacterStats = () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        "Gordon Freeman": { winRate: 52 },
        "Rebel": { winRate: 48 },
        "Medic": { winRate: 58 },
        "Engineer": { winRate: 44 },
        "Security Guard": { winRate: 50 },
        "Mayor": { winRate: 62 },
        "The Flesh": { winRate: 55 }
      });
    }, 500);
  });
  // Uncomment the below lines to make an actual API call
  // try {
  //   return await api.get('/api/characters/stats');
  // } catch (error) {
  //   throw new Error(error?.response?.data?.error || error.message);
  // }
}