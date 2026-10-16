const mongoose = require('mongoose');

const adminSchema = new mongoose.Schema(
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
             lowercase: true, 
             trim: true 
            },

        //Like user, heddien from queries
        passwordHash: { 
            type: String, 
            required: true, 
            select: false 
        },

        role:{
            type: String,
            enum: ['admin', 'super_admin'],  //List of values that Mongoose will allow for this field
            default: 'admin'
        },
    },
    {
        timestamps: true,
        collection: 'admins'
    }
);
    
    
module.exports = mongoose.model('Admin', adminSchema);