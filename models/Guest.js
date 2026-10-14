const mongoose = require('mongoose');

const SEVEN_DAYS =60 * 60 * 24 *7;

const guestSchema = new mongoose.Schema({
    guestId: {
        type: String,
        required: true,
        unique: true
    },
    // MongoDB deletes the record after 7 days
    createdAt:{
        type: Date,
        default: Date.now,
        expires: SEVEN_DAYS
    }
});

module.exports = mongoose.model('Guest', guestSchema)