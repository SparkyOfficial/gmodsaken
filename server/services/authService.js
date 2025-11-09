const axios = require('axios');
const crypto = require('crypto');
const Player = require('../models/Player');

class AuthService {
    constructor() {
        this.steamApiKey = process.env.STEAM_API_KEY;
        this.returnUrl = process.env.STEAM_RETURN_URL;
        this.steamOpenIdUrl = 'https://steamcommunity.com/openid/login';
    }

    /**
     * Initiate Steam OpenID login
     * @param {Object} req - Express request object
     * @returns {string} - Steam OpenID redirect URL
     */
    initiateLogin(req) {
        const params = new URLSearchParams({
            'openid.ns': 'http://specs.openid.net/auth/2.0',
            'openid.mode': 'checkid_setup',
            'openid.return_to': this.returnUrl,
            'openid.realm': this.returnUrl.split('/auth')[0],
            'openid.identity': 'http://specs.openid.net/auth/2.0/identifier_select',
            'openid.claimed_id': 'http://specs.openid.net/auth/2.0/identifier_select'
        });

        return `${this.steamOpenIdUrl}?${params.toString()}`;
    }

    /**
     * Handle Steam OpenID callback and verify authentication
     * @param {Object} req - Express request object
     * @returns {Promise<string|null>} - Steam ID if valid, null otherwise
     */
    async handleCallback(req) {
        try {
            // Verify the OpenID response
            const isValid = await this.verifyOpenIdResponse(req.query);
            
            if (!isValid) {
                return null;
            }

            // Extract Steam ID from claimed_id
            const claimedId = req.query['openid.claimed_id'];
            const steamIdMatch = claimedId.match(/\/id\/(\d+)$/);
            
            if (!steamIdMatch) {
                return null;
            }

            const steamId = steamIdMatch[1];

            // Fetch Steam profile data
            const profileData = await this.fetchSteamProfile(steamId);
            
            if (!profileData) {
                return null;
            }

            // Create or update player in database
            await this.createOrUpdatePlayer(steamId, profileData);

            return steamId;
        } catch (error) {
            console.error('Error handling Steam callback:', error);
            return null;
        }
    }

    /**
     * Verify OpenID response from Steam
     * @param {Object} query - Query parameters from callback
     * @returns {Promise<boolean>} - True if valid
     */
    async verifyOpenIdResponse(query) {
        try {
            const params = new URLSearchParams({
                ...query,
                'openid.mode': 'check_authentication'
            });

            const response = await axios.post(this.steamOpenIdUrl, params.toString(), {
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                }
            });

            return response.data.includes('is_valid:true');
        } catch (error) {
            console.error('Error verifying OpenID response:', error);
            return false;
        }
    }

    /**
     * Fetch Steam profile data from Steam Web API
     * @param {string} steamId - Steam ID
     * @returns {Promise<Object|null>} - Profile data or null
     */
    async fetchSteamProfile(steamId) {
        try {
            if (!this.steamApiKey) {
                console.error('Steam API key not configured');
                return null;
            }

            const url = `https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/`;
            const response = await axios.get(url, {
                params: {
                    key: this.steamApiKey,
                    steamids: steamId
                }
            });

            const players = response.data?.response?.players;
            
            if (!players || players.length === 0) {
                return null;
            }

            const player = players[0];
            
            return {
                steamId: player.steamid,
                username: player.personaname,
                avatar: player.avatarfull || player.avatarmedium || player.avatar,
                profileUrl: player.profileurl
            };
        } catch (error) {
            console.error('Error fetching Steam profile:', error);
            return null;
        }
    }

    /**
     * Create or update player in database
     * @param {string} steamId - Steam ID
     * @param {Object} profileData - Profile data from Steam
     * @returns {Promise<Object>} - Player document
     */
    async createOrUpdatePlayer(steamId, profileData) {
        try {
            const player = await Player.findOneAndUpdate(
                { steamId },
                {
                    steamId: profileData.steamId,
                    username: profileData.username,
                    avatar: profileData.avatar,
                    lastSeen: new Date()
                },
                {
                    upsert: true,
                    new: true,
                    setDefaultsOnInsert: true
                }
            );

            return player;
        } catch (error) {
            console.error('Error creating/updating player:', error);
            throw error;
        }
    }

    /**
     * Create session for authenticated user
     * @param {Object} req - Express request object
     * @param {string} steamId - Steam ID
     * @returns {Promise<Object>} - Session data
     */
    async createSession(req, steamId) {
        return new Promise((resolve, reject) => {
            req.session.regenerate((err) => {
                if (err) {
                    return reject(err);
                }

                req.session.steamId = steamId;
                req.session.createdAt = new Date();

                req.session.save((err) => {
                    if (err) {
                        return reject(err);
                    }
                    resolve({
                        sessionId: req.session.id,
                        steamId: steamId
                    });
                });
            });
        });
    }

    /**
     * Verify if session is valid
     * @param {Object} req - Express request object
     * @returns {boolean} - True if session is valid
     */
    verifySession(req) {
        return !!(req.session && req.session.steamId);
    }

    /**
     * Destroy session (logout)
     * @param {Object} req - Express request object
     * @returns {Promise<void>}
     */
    async destroySession(req) {
        return new Promise((resolve, reject) => {
            req.session.destroy((err) => {
                if (err) {
                    return reject(err);
                }
                resolve();
            });
        });
    }

    /**
     * Get current user from session
     * @param {Object} req - Express request object
     * @returns {Promise<Object|null>} - User data or null
     */
    async getCurrentUser(req) {
        if (!this.verifySession(req)) {
            return null;
        }

        try {
            const player = await Player.findOne({ steamId: req.session.steamId });
            return player;
        } catch (error) {
            console.error('Error getting current user:', error);
            return null;
        }
    }
}

module.exports = new AuthService();
