const authService = require('../services/authService');

/**
 * Middleware to require authentication
 * Use this on routes that need authenticated users
 */
function requireAuth(req, res, next) {
    if (!authService.verifySession(req)) {
        return res.status(401).json({
            error: 'Unauthorized',
            message: 'Authentication required'
        });
    }
    next();
}

/**
 * Middleware to optionally load user if authenticated
 * Use this on routes where authentication is optional
 */
async function optionalAuth(req, res, next) {
    if (authService.verifySession(req)) {
        try {
            req.user = await authService.getCurrentUser(req);
        } catch (error) {
            console.error('Error loading user:', error);
        }
    }
    next();
}

/**
 * Middleware to require admin privileges
 * Use this on routes that need admin access
 */
async function requireAdmin(req, res, next) {
    if (!authService.verifySession(req)) {
        return res.status(401).json({
            error: 'Unauthorized',
            message: 'Authentication required'
        });
    }

    try {
        const user = await authService.getCurrentUser(req);
        
        if (!user || !user.isAdmin) {
            return res.status(403).json({
                error: 'Forbidden',
                message: 'Admin privileges required'
            });
        }

        req.user = user;
        next();
    } catch (error) {
        console.error('Error verifying admin:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to verify admin status'
        });
    }
}

module.exports = {
    requireAuth,
    optionalAuth,
    requireAdmin
};
