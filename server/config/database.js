const mongoose = require('mongoose');
require('dotenv').config();

let isConnected = false;
let connectionAttempts = 0;
const MAX_RETRY_ATTEMPTS = 5;
const RETRY_DELAY = 5000; // 5 seconds

const connectDB = async () => {
  // If already connected, return
  if (isConnected) {
    console.log("MongoDB already connected");
    return;
  }

  // Check if DATABASE_URL is provided
  if (!process.env.DATABASE_URL) {
    console.error("ERROR: DATABASE_URL environment variable is not set");
    process.exit(1);
  }

  try {
    connectionAttempts++;
    console.log(`Attempting to connect to MongoDB (attempt ${connectionAttempts}/${MAX_RETRY_ATTEMPTS})...`);

    const conn = await mongoose.connect(process.env.DATABASE_URL, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });

    isConnected = true;
    connectionAttempts = 0; // Reset on successful connection
    console.log("✓ MongoDB connected successfully");
    console.log(`  Database: ${conn.connection.name}`);
    console.log(`  Host: ${conn.connection.host}`);

  } catch (error) {
    console.error("✗ MongoDB connection error:", error.message);

    // Retry logic
    if (connectionAttempts < MAX_RETRY_ATTEMPTS) {
      console.log(`Retrying in ${RETRY_DELAY / 1000} seconds...`);
      setTimeout(connectDB, RETRY_DELAY);
    } else {
      console.error(`Failed to connect to MongoDB after ${MAX_RETRY_ATTEMPTS} attempts`);
      process.exit(1);
    }
  }
};

// Handle connection events
mongoose.connection.on("connected", () => {
  isConnected = true;
  console.log("MongoDB connection established");
});

mongoose.connection.on("error", (err) => {
  console.error("MongoDB connection error:", err);
  isConnected = false;
});

mongoose.connection.on("disconnected", () => {
  console.log("MongoDB disconnected");
  isConnected = false;
  
  // Attempt to reconnect
  if (connectionAttempts < MAX_RETRY_ATTEMPTS) {
    console.log("Attempting to reconnect...");
    setTimeout(connectDB, RETRY_DELAY);
  }
});

mongoose.connection.on('reconnected', () => {
  console.info('MongoDB reconnected');
  isConnected = true;
});

// Graceful shutdown
process.on("SIGINT", async () => {
  try {
    await mongoose.connection.close();
    console.log("MongoDB connection closed through app termination");
    process.exit(0);
  } catch (err) {
    console.error("Error closing MongoDB connection:", err);
    process.exit(1);
  }
});

module.exports = { 
  connectDB, 
  isConnected: () => isConnected 
};
