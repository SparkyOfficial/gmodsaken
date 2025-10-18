import api from './api';

// Description: Get gameplay rules
// Endpoint: GET /api/rules/gameplay
// Request: {}
// Response: { categories: Array<any> }
export const getRules = () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        categories: [
          {
            name: "General Rules",
            type: "general",
            description: "Basic rules that apply to all players",
            rules: [
              {
                title: "No Exploiting",
                severity: "critical",
                description: "Using map exploits, glitches, or unintended game mechanics is strictly forbidden",
                examples: [
                  "Getting stuck in walls or unreachable areas",
                  "Using console commands to gain advantages",
                  "Exploiting respawn mechanics"
                ]
              },
              {
                title: "Play Your Role",
                severity: "important",
                description: "Players must play according to their assigned role and character",
                examples: [
                  "Survivors must try to survive, not help the killer",
                  "The Flesh must hunt survivors, not idle",
                  "Use character abilities appropriately"
                ]
              },
              {
                title: "No Ghosting",
                severity: "critical",
                description: "Dead players cannot give information to living players",
                examples: [
                  "Revealing killer location via voice/text",
                  "Providing tactical information after death",
                  "Using external communication to share game info"
                ]
              }
            ]
          },
          {
            name: "Survivor Rules",
            type: "survivor",
            description: "Specific rules for survivor players",
            rules: [
              {
                title: "Team Coordination",
                severity: "important",
                description: "Work together but don't abuse communication systems",
                examples: [
                  "Use Mayor's phone appropriately",
                  "Share resources when possible",
                  "Don't spam communication tools"
                ]
              },
              {
                title: "No Camping Spawn",
                severity: "important",
                description: "Don't camp at spawn locations or exploit safe areas",
                examples: [
                  "Staying in spawn areas beyond reasonable time",
                  "Exploiting invisible barriers",
                  "Hiding in inaccessible locations"
                ]
              },
              {
                title: "Resource Management",
                severity: "normal",
                description: "Use abilities and equipment fairly and strategically",
                examples: [
                  "Don't waste Engineer buildings",
                  "Share healing when appropriate",
                  "Use stamina-based abilities wisely"
                ]
              }
            ]
          },
          {
            name: "Killer Rules",
            type: "killer",
            description: "Specific rules for The Flesh player",
            rules: [
              {
                title: "No Spawn Camping",
                severity: "important",
                description: "Don't camp survivor spawn areas at round start",
                examples: [
                  "Waiting at spawn points immediately after round start",
                  "Blocking spawn exits",
                  "Targeting players before they can move"
                ]
              },
              {
                title: "Active Hunting",
                severity: "important",
                description: "Actively hunt survivors, don't idle or waste time",
                examples: [
                  "Moving around the map to find survivors",
                  "Using abilities effectively",
                  "Not hiding or avoiding combat"
                ]
              },
              {
                title: "Fair Ability Use",
                severity: "normal",
                description: "Use killer abilities appropriately and not excessively",
                examples: [
                  "Don't spam headcrab spawning",
                  "Use eye laser strategically",
                  "Balance between different attack methods"
                ]
              }
            ]
          },
          {
            name: "Timing Rules",
            type: "timing",
            description: "Rules related to round timing and flow",
            rules: [
              {
                title: "Ready Up Promptly",
                severity: "normal",
                description: "Don't delay round starts by being AFK in lobby",
                examples: [
                  "Select character within reasonable time",
                  "Don't go AFK during character selection",
                  "Respect other players' time"
                ]
              },
              {
                title: "No Round Stalling",
                severity: "important",
                description: "Don't artificially extend rounds beyond normal gameplay",
                examples: [
                  "Hiding to waste time as survivor",
                  "Avoiding combat as The Flesh",
                  "Using exploits to extend round duration"
                ]
              }
            ]
          }
        ]
      });
    }, 500);
  });
  // Uncomment the below lines to make an actual API call
  // try {
  //   return await api.get('/api/rules/gameplay');
  // } catch (error) {
  //   throw new Error(error?.response?.data?.error || error.message);
  // }
}

// Description: Get server rules and conduct guidelines
// Endpoint: GET /api/rules/server
// Request: {}
// Response: { sections: Array<any>, conduct: any, reporting: any }
export const getServerRules = () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        sections: [
          {
            title: "Chat and Communication",
            description: "Rules regarding text and voice communication",
            rules: [
              {
                title: "No Harassment",
                description: "Harassment, bullying, or toxic behavior towards other players is not tolerated",
                penalty: "Temporary mute or ban"
              },
              {
                title: "No Spam",
                description: "Don't spam chat, voice, or communication systems",
                penalty: "Warning then mute"
              },
              {
                title: "English Only",
                description: "Primary server language is English for effective communication",
                penalty: "Warning"
              },
              {
                title: "No Advertising",
                description: "Don't advertise other servers, Discord servers, or external content",
                penalty: "Kick or ban"
              }
            ]
          },
          {
            title: "Player Conduct",
            description: "General behavior expectations",
            rules: [
              {
                title: "Respect All Players",
                description: "Treat all players with respect regardless of skill level or experience",
                penalty: "Warning to permanent ban"
              },
              {
                title: "No Discrimination",
                description: "Discrimination based on race, gender, religion, or other factors is forbidden",
                penalty: "Immediate ban"
              },
              {
                title: "Follow Admin Instructions",
                description: "Listen to and follow instructions from server administrators",
                penalty: "Escalating punishments"
              },
              {
                title: "No Impersonation",
                description: "Don't impersonate admins, other players, or public figures",
                penalty: "Kick or ban"
              }
            ]
          },
          {
            title: "Technical Rules",
            description: "Rules regarding game modifications and technical aspects",
            rules: [
              {
                title: "No Cheating",
                description: "Any form of cheating, hacking, or unfair advantage tools are prohibited",
                penalty: "Permanent ban"
              },
              {
                title: "No Lag Switching",
                description: "Intentionally causing network issues to gain advantages",
                penalty: "Temporary to permanent ban"
              },
              {
                title: "Approved Mods Only",
                description: "Only use server-approved modifications and addons",
                penalty: "Warning to kick"
              }
            ]
          }
        ],
        conduct: {
          encouraged: [
            {
              title: "Help New Players",
              description: "Guide newcomers and help them learn the game mechanics"
            },
            {
              title: "Good Sportsmanship",
              description: "Be gracious in victory and defeat, congratulate good plays"
            },
            {
              title: "Constructive Feedback",
              description: "Provide helpful suggestions and constructive criticism"
            },
            {
              title: "Team Communication",
              description: "Communicate effectively with your team using appropriate channels"
            }
          ],
          prohibited: [
            {
              title: "Rage Quitting",
              description: "Leaving immediately after dying or losing repeatedly"
            },
            {
              title: "Griefing Teammates",
              description: "Intentionally hindering your own team's success"
            },
            {
              title: "Excessive Complaining",
              description: "Constantly complaining about game balance or other players"
            },
            {
              title: "Meta Gaming",
              description: "Using external information not available in-game"
            }
          ]
        },
        reporting: {
          methods: [
            {
              name: "In-Game Report",
              description: "Use !report command followed by player name and reason",
              responseTime: "5-10 minutes"
            },
            {
              name: "Discord Report",
              description: "Contact admins on the official Discord server",
              responseTime: "30-60 minutes"
            },
            {
              name: "Forum Report",
              description: "Create a detailed report on the community forums",
              responseTime: "1-24 hours"
            }
          ],
          note: "False reports or abuse of the reporting system will result in penalties for the reporter. Always provide evidence when possible and be truthful in your reports."
        }
      });
    }, 500);
  });
  // Uncomment the below lines to make an actual API call
  // try {
  //   return await api.get('/api/rules/server');
  // } catch (error) {
  //   throw new Error(error?.response?.data?.error || error.message);
  // }
}