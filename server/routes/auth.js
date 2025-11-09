const express = require('express');
const router = express.Router();
const authService = require('../services/authService');

/**
 * GET /auth/steam
 * Initiate Steam OpenID login
 */
router.get('/steam', (req, res) => {
    try {
        const redirectUrl = authService.initiateLogin(req);
        res.redirect(redirectUrl);
    } catch (error) {
        console.error('Error initiating Steam login:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to initiate Steam login'
        });
    }
});

/**
 * GET /auth/steam/callback
 * Handle Steam OpenID callback
 */
router.get('/steam/callback', async (req, res) => {
    try {
        // Verify OpenID response and get Steam ID
        const steamId = await authService.handleCallback(req);

        if (!steamId) {
            return res.status(401).json({
                error: 'Authentication Failed',
                message: 'Failed to authenticate with Steam'
            });
        }

        // Create session
        await authService.createSession(req, steamId);

        // Redirect to frontend (adjust URL based on your frontend)
        const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:5173';
        res.redirect(`${frontendUrl}/profile`);
    } catch (error) {
        console.error('Error handling Steam callback:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to complete authentication'
        });
    }
});

/**
 * POST /auth/logout
 * Logout user and destroy session
 */
router.post('/logout', async (req, res) => {
    try {
        if (!authService.verifySession(req)) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'No active session'
            });
        }

        await authService.destroySession(req);

        res.json({
            success: true,
            message: 'Logged out successfully'
        });
    } catch (error) {
        console.error('Error logging out:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to logout'
        });
    }
});

/**
 * GET /auth/me
 * Get current authenticated user
 */
router.get('/me', async (req, res) => {
    try {
        if (!authService.verifySession(req)) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'Not authenticated'
            });
        }

        const user = await authService.getCurrentUser(req);

        if (!user) {
            return res.status(404).json({
                error: 'Not Found',
                message: 'User not found'
            });
        }

        // Return user data without sensitive fields
        res.json({
            steamId: user.steamId,
            username: user.username,
            avatar: user.avatar,
            level: user.level,
            xp: user.xp,
            stats: user.stats,
            favoriteCharacter: user.favoriteCharacter,
            achievements: user.achievements
        });
    } catch (error) {
        console.error('Error getting current user:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to get user data'
        });
    }
});

module.exports = router;
