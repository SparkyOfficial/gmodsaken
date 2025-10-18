import api from './api';

// Description: Get gameplay information
// Endpoint: GET /api/gameplay/info
// Request: {}
// Response: { roundStructure: Array<any>, victoryConditions: any, playerRequirements: any, coreMechanics: Array<string>, detailedPhases: Array<any>, mechanics: Array<any> }
export const getGameplayInfo = () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        roundStructure: [
          {
            name: "Pre-Round Lobby",
            duration: "40 seconds",
            description: "Character selection and player readiness check"
          },
          {
            name: "Round Start",
            duration: "Instant",
            description: "Players teleport to spawn locations"
          },
          {
            name: "Gameplay Phase",
            duration: "6 minutes",
            description: "Main survival gameplay"
          },
          {
            name: "Round End",
            duration: "10 seconds",
            description: "Victory screen and return to lobby"
          }
        ],
        victoryConditions: {
          survivors: "At least one survivor must remain alive when the 6-minute timer expires",
          killer: "The Flesh must eliminate all survivors before time runs out"
        },
        playerRequirements: {
          minimum: 3,
          maximum: 16,
          lobbyTimer: "40 seconds"
        },
        coreMechanics: [
          "Round-based gameplay",
          "Asymmetric roles",
          "Character-specific abilities",
          "Stamina system",
          "Health and armor management",
          "Team coordination"
        ],
        detailedPhases: [
          {
            name: "Lobby Phase",
            duration: "40 seconds",
            color: "bg-blue-500",
            description: "Players select characters and prepare for the round",
            activities: [
              "Character selection",
              "Player readiness check",
              "Countdown timer",
              "Chat communication"
            ],
            playerActions: [
              "Choose character",
              "Ready up",
              "Communicate strategy",
              "Wait for other players"
            ]
          },
          {
            name: "Deployment Phase",
            duration: "Instant",
            color: "bg-yellow-500",
            description: "Players are teleported to their starting positions",
            activities: [
              "Role assignment",
              "Teleportation",
              "Round timer start",
              "HUD activation"
            ],
            playerActions: [
              "Automatically teleported",
              "Assess surroundings",
              "Begin strategy execution"
            ]
          },
          {
            name: "Survival Phase",
            duration: "6 minutes",
            color: "bg-red-500",
            description: "Main gameplay where survivors must outlast The Flesh",
            activities: [
              "Combat encounters",
              "Team coordination",
              "Ability usage",
              "Environmental navigation"
            ],
            playerActions: [
              "Survive and fight",
              "Use character abilities",
              "Coordinate with team",
              "Manage resources"
            ]
          }
        ],
        mechanics: [
          {
            name: "Combat System",
            type: "combat",
            description: "How players interact in combat situations",
            details: [
              {
                aspect: "Damage Types",
                value: "Melee & Ranged",
                explanation: "Different weapons deal different types of damage"
              },
              {
                aspect: "Slowdown Effects",
                value: "Temporary",
                explanation: "Weapons can slow down The Flesh temporarily"
              },
              {
                aspect: "Weapon Reliability",
                value: "Variable",
                explanation: "Some weapons may jam or have cooldowns"
              }
            ]
          },
          {
            name: "Stamina System",
            type: "movement",
            description: "Energy management for certain abilities",
            details: [
              {
                aspect: "Security Guard Club",
                value: "35 stamina per swing",
                explanation: "Minimum 35 stamina required to attack"
              },
              {
                aspect: "Regeneration",
                value: "Over time",
                explanation: "Stamina regenerates when not in use"
              }
            ]
          },
          {
            name: "Healing System",
            type: "survival",
            description: "Health restoration mechanics",
            details: [
              {
                aspect: "Medic Healing",
                value: "10 HP every 3 seconds",
                explanation: "Can heal self and teammates"
              },
              {
                aspect: "Mayor Aura",
                value: "+1 armor per second",
                explanation: "Passive buff for nearby allies"
              }
            ]
          },
          {
            name: "Building System",
            type: "utility",
            description: "Construction abilities for Engineer",
            details: [
              {
                aspect: "Turrets",
                value: "Defensive",
                explanation: "Automated defense structures"
              },
              {
                aspect: "Dispensers",
                value: "Supply",
                explanation: "Provide resources to team"
              },
              {
                aspect: "Teleporters",
                value: "Mobility",
                explanation: "Quick movement across map"
              }
            ]
          }
        ]
      });
    }, 500);
  });
  // Uncomment the below lines to make an actual API call
  // try {
  //   return await api.get('/api/gameplay/info');
  // } catch (error) {
  //   throw new Error(error?.response?.data?.error || error.message);
  // }
}

// Description: Get map information
// Endpoint: GET /api/gameplay/map
// Request: {}
// Response: { name: string, description: string, gameArea: string, lobbyArea: string, spawnLocations: Array<any>, strategicLocations: Array<any> }
export const getMapInfo = () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        name: "gm_construct",
        description: "Classic Garry's Mod construction map adapted for survival horror",
        gameArea: "Water area and surrounding structures",
        lobbyArea: "Top floor of main building",
        spawnLocations: [
          {
            name: "Water Area Spawns",
            type: "survivor",
            description: "Random spawn points near the water for survivors"
          },
          {
            name: "Dark Room",
            type: "killer",
            description: "Isolated spawn location for The Flesh"
          }
        ],
        strategicLocations: [
          {
            name: "Main Building",
            importance: "High",
            description: "Central structure with multiple levels and rooms",
            features: ["Multiple floors", "Cover opportunities", "Escape routes"]
          },
          {
            name: "Water Area",
            importance: "Medium",
            description: "Open area with limited cover but good mobility",
            features: ["Open space", "Limited cover", "High mobility"]
          },
          {
            name: "Underground Tunnel",
            importance: "High",
            description: "Narrow passages that can be used for ambushes or escapes",
            features: ["Tight spaces", "Ambush potential", "Alternative routes"]
          },
          {
            name: "Rooftop Areas",
            importance: "Medium",
            description: "Elevated positions offering tactical advantages",
            features: ["High ground", "Long sightlines", "Limited access"]
          }
        ]
      });
    }, 500);
  });
  // Uncomment the below lines to make an actual API call
  // try {
  //   return await api.get('/api/gameplay/map');
  // } catch (error) {
  //   throw new Error(error?.response?.data?.error || error.message);
  // }
}