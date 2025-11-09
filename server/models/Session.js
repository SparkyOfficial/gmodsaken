const mongoose = require('mongoose');

const SessionSchema = new mongoose.Schema({
  sessionId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  steamId: {
    type: String,
    required: true,
    index: true,
    validate: {
      validator: function(v) {
        return /^[0-9]{17}$/.test(v);
      },
      message: props => `${props.value} is not a valid Steam ID!`
    }
  },
  expiresAt: {
    type: Date,
    required: true,
    index: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Index for automatic cleanup of expired sessions
SessionSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// Method to check if session is expired
SessionSchema.methods.isExpired = function() {
  return new Date() > this.expiresAt;
};

// Method to extend session
SessionSchema.methods.extend = function(days = 7) {
  this.expiresAt = new Date(Date.now() + days * 24 * 60 * 60 * 1000);
  return this.save();
};

// Static method to cleanup expired sessions
SessionSchema.statics.cleanupExpired = function() {
  return this.deleteMany({ expiresAt: { $lt: new Date() } });
};

// Static method to get active sessions for a user
SessionSchema.statics.getActiveSessions = function(steamId) {
  return this.find({
    steamId: steamId,
    expiresAt: { $gt: new Date() }
  });
};

module.exports = mongoose.model('Session', SessionSchema);
