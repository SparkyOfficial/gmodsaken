const mongoose = require('mongoose');

const MatchPlayerSchema = new mongoose.Schema({
  steamId: {
    type: String,
    required: true,
    index: true
  },
  team: {
    type: String,
    required: true,
    enum: ['SURVIVOR', 'KILLER', 'SPECTATOR']
  },
  character: {
    type: String,
    required: true
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
  xpEarned: {
    type: Number,
    default: 0,
    min: 0
  },
  questsCompleted: [{
    type: String
  }]
}, { _id: false });

const MatchSchema = new mongoose.Schema({
  matchId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  mapName: {
    type: String,
    required: true
  },
  gameState: {
    type: String,
    required: true,
    enum: ['LOBBY', 'PREPARING', 'PLAYING', 'LMS_PLAYING', 'ENDING']
  },
  winner: {
    type: String,
    required: true,
    enum: ['KILLER', 'SURVIVORS', 'TIMEOUT', 'DRAW']
  },
  duration: {
    type: Number,
    required: true,
    min: 0,
    comment: 'Match duration in seconds'
  },
  players: [MatchPlayerSchema],
  startedAt: {
    type: Date,
    required: true,
    index: -1 // Index for recent matches queries (descending)
  },
  endedAt: {
    type: Date,
    required: true
  }
}, {
  timestamps: true
});

// Virtual for survivor count
MatchSchema.virtual('survivorCount').get(function() {
  return this.players.filter(p => p.team === 'SURVIVOR').length;
});

// Virtual for killer count
MatchSchema.virtual('killerCount').get(function() {
  return this.players.filter(p => p.team === 'KILLER').length;
});

// Method to get match summary
MatchSchema.methods.getSummary = function() {
  return {
    matchId: this.matchId,
    mapName: this.mapName,
    winner: this.winner,
    duration: this.duration,
    playerCount: this.players.length,
    survivorCount: this.survivorCount,
    killerCount: this.killerCount,
    startedAt: this.startedAt,
    endedAt: this.endedAt
  };
};

// Static method to get recent matches
MatchSchema.statics.getRecentMatches = function(limit = 10) {
  return this.find()
    .sort({ startedAt: -1 })
    .limit(limit)
    .select('matchId mapName winner duration players startedAt endedAt');
};

// Static method to get player match history
MatchSchema.statics.getPlayerMatches = function(steamId, limit = 20) {
  return this.find({ 'players.steamId': steamId })
    .sort({ startedAt: -1 })
    .limit(limit)
    .select('matchId mapName winner duration players startedAt endedAt');
};

// Ensure virtuals are included in JSON
MatchSchema.set('toJSON', { virtuals: true });
MatchSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Match', MatchSchema);
