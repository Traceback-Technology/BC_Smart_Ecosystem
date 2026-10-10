const User = require('../models/User');
const createCrudController = require('./CRUDFactory');

const base = createCrudController(User);

const findByEmail = async (email) => {
    return User.findOne({ email: email.toLowerCase().trim() });
};

const setOtpCode = async (userId, otpCode, otpExpiresAt) => {
    return User.findByIdAndUpdate
    (
        userId,
        { $set: { otpCode, otpExpiresAt } },
        { returnDocument: 'after' }
    );
};

const verifyOtp = async (userId, submittedOtp) => {
    const user = await User.findById(userId);
    if (!user || !user.otpCode) return {success: false, reason: 'No OTP on record'}; 
    if (user.otpExpiresAt &&  user.otpExpiresAt < new Date()) {
        return {success: false, reason: 'OTP expired'};
    }
    if (user.otpCode !== submittedOtp) {
        return {success: false, reason: 'Invalid OTP'};
    };

    user.isVerified = true;
    user.otpCode = null;
    user.otpExpiresAt = null;
    await user.save();
    return {success: true, user};
};

module.exports = 
{
    ...base,
    findByEmail,
    setOtpCode,
    verifyOtp
};