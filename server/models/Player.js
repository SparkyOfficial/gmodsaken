const mongoose = require('mongoose');

const PlayerSchema = new mongoose.Schema({
  steamId: {
    type: String,
    required: true,
    unique: true,
    index: true,
    validate: {
      validator: function(v) {
        return /^[0-9]{17}$/.test(v);
      },
      message: props => `${props.value} is not a valid Steam ID!`
    }
  },
  username: {
    type: String,
    required: true,
    trim: true
  },
  avatar: {
    type: String,
    required: true
  },
  level: {
    type: Number,
    default: 1,
    min: 1
  },
  xp: {
    type: Number,
    default: 0,
    min: 0,
    index: -1 // Index for leaderboard queries (descending)
  },
  stats: {
    gamesPlayed: {
      type: Number,
      default: 0,
      min: 0
    },
    wins: {
      type: Number,
      default: 0,
      min: 0,
      index: -1 // Index for win leaderboard
    },
    losses: {
      type: Number,
      default: 0,
      min: 0
    },
    kills: {
      type: Number,
      default: 0,
      min: 0
    },
    deaths: {
      type: Number,
      default: 0,
      min: 0
    },
    questsCompleted: {
      type: Number,
      default: 0,
      min: 0
    },
    totalPlaytime: {
      type: Number,
      default: 0,
      min: 0,
      comment: 'Total playtime in seconds'
    }
  },
  favoriteCharacter: {
    type: String,
    default: null
  },
  achievements: [{
    type: String
  }],
  lastSeen: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true // Adds createdAt and updatedAt automatically
});

// Virtual for win rate
PlayerSchema.virtual('winRate').get(function() {
  if (this.stats.gamesPlayed === 0) return 0;
  return (this.stats.wins / this.stats.gamesPlayed) * 100;
});

// Virtual for K/D ratio
PlayerSchema.virtual('kdRatio').get(function() {
  if (this.stats.deaths === 0) return this.stats.kills;
  return this.stats.kills / this.stats.deaths;
});

// Method to calculate level from XP
PlayerSchema.methods.calculateLevel = function() {
  return Math.floor(Math.sqrt(this.xp / 100));
};

// Method to get XP required for next level
PlayerSchema.methods.xpForNextLevel = function() {
  const currentLevel = this.calculateLevel();
  return Math.pow(currentLevel + 1, 2) * 100;
};

// Method to add XP and update level
PlayerSchema.methods.addXP = function(amount) {
  this.xp += amount;
  this.level = this.calculateLevel();
  return this.save();
};

// Method to update last seen
PlayerSchema.methods.updateLastSeen = function() {
  this.lastSeen = new Date();
  return this.save();
};

// Static method to get leaderboard
PlayerSchema.statics.getLeaderboard = function(limit = 100, sortBy = 'xp') {
  const sortOptions = {};
  sortOptions[`stats.${sortBy}`] = sortBy === 'xp' ? -1 : -1;
  
  return this.find()
    .sort(sortOptions)
    .limit(limit)
    .select('steamId username avatar level xp stats');
};

// Ensure virtuals are included in JSON
PlayerSchema.set('toJSON', { virtuals: true });
PlayerSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Player', PlayerSchema);
