const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
    {
        fullName: {
            type: String,
            required: true,
            trim: true
        },

        email: {
            type: String,
            required: true,
            unique: true,
            // convert email to lowercase and trim whitespace
            lowercase: true,
            trim: true
        },

        phoneNumber: {
            type: String,
            required: true,
            unique: true,
            trim: true
        },

        passwordHash: {
            type: String,
            required: true,
            select: false // never return the password hash in queries
        },

        //Evryone who registers is a "user" by default
        role: {
            type: String,
            enum: ['user', 'admin'],
            default: 'user'
        },

        studentNumber: {
            type: String,
            trim: true
        },

        isVerified: {
            type: Boolean,
            default: false
        },

        //support for OTP verification
        otpCode: {
            type: String,
            default: null
        },

        otpExpiresAt: {
            type: Date,
            default: null
        },

    },
    {
        timestamps: true,
        collection: 'users'
    }
);

module.exports = mongoose.model('User', userSchema);