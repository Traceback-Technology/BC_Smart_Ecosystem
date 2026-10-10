//opens the connection to the database using mongoose and the connection string from the .env file
//All the other files that need to connect to the database will import this file and call the connectDB function to establish the connection
require('dotenv').config();
const mongoose = require('mongoose');

async function connectDB() {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {dbName: 'BC_eats'});
    console.log('MongoDB connected successfully');
  } catch (error) {
    console.error('MongoDB connection error:', error.message);
  }
}

module.exports = connectDB;