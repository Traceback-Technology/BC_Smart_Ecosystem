const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const User = require('../models/User');
const Guest = require('../models/Guest');
const { makeUserToken, makeGuestToken } = require('../utils/token');

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
// min 8 chars, upper + lower + digit (the design's "strict rules")
const PASSWORD_RE = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;

const COOKIE_OPTIONS = {
    httpOnly: true,                         // JS in the browser can't read it
    secure: process.env.NODE_ENV === 'production', // HTTPs only in prod
    sameSite: 'lax'
};
const COOKIE_MAX_AGE = 8 * 60 * 60 * 1000; // matches 8h token

//A fake hash so "unknown email" takes as long as "wrong password"
const DUMMY_HASH = bcrypt.hashSync('not-a-real-password', 12);

function sendUserSession(res, user, status) {
    const token = makeUserToken(user);
    res.cookie('token', token, { ...COOKIE_OPTIONS, maxAge: COOKIE_MAX_AGE });
    return res.status(status).json({
        token,
        user: { id: user._id, email: user.email, role: user.role },
    });
}


//! Implementation notes: One error message for sign-in failures. errors should not expose sensitive information.
//! If we said "email not found", attackers could discover which emails have accounts. 
//! The DUMMY_HASH trick stops them inferring the same thing from reponse timing. 
exports.register = async (req, res, next) => {
    try {
        const { fullName, email, phoneNumber, studentNumber, password } = req.body || {};

        if (typeof fullName !== 'string' || !fullName.trim()) {
            return res.status(400).json({ message: 'A valid full name is required' });
        }
        if (typeof email !== 'string' || !EMAIL_RE.test(email)) {
            return res.status(400).json({ message: 'A valid email is required' });
        }
        if (typeof password !== 'string' || !PASSWORD_RE.test(password)) {
            return res.status(400).json({
                message: 'Password must be at least 8 characters with upper case, lower case and a digit',
            });
        }
        if (typeof phoneNumber !== 'string' || !phoneNumber.trim()) {
            return res.status(400).json({ message: 'A valid phone number is required' });
        }


        //* Cost Factor 12 for bcrypt is a sensible balance of security and speed.
        const passwordHash = await bcrypt.hash(password, 12);
        const user = await User.create({ fullName, email, phoneNumber, studentNumber, passwordHash });
        return sendUserSession(res, user, 201); // session begins at registration
    } catch (err) {
        if (err.code === 11000) {
            const field = Object.keys(err.keyPattern) || {}[0];
            const label = field === 'phoneNumber' ? 'phone number' : 'email'; 
            return res.status(409).json({ message: `An account with this ${label} already exists` });
        }
        next(err);
    }
}

exports.signin = async (req, res, next) => {
    try {
        const { email, password } = req.body || {};
        if (typeof email !== 'string' || typeof password !== 'string') {
            return res.status(400).json({ message: 'Email and password are required' });
        }

        const user = await User.findOne({ email: email.toLowerCase().trim() }).select('+passwordHash');
        const ok = await bcrypt.compare(password, user ? user.passwordHash : DUMMY_HASH);

        if (!user || !ok) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }
        return sendUserSession(res, user, 200);
    } catch (err) {
        next(err);
    }
}
exports.guestSession = async (req, res, next) => {
    try {
        const guestId = crypto.randomUUID();
        await Guest.create({ guestId });
        //Guests get the token in the body only, no cookie
        return res.status(201).json({ token: makeGuestToken(guestId) });
    } catch (err) {
        next(err);
    }
}

exports.signout = (req, res) => {
    //Options must match the ones used to set the cookie, or it won't clear 
    res.clearCookie('token', COOKIE_OPTIONS);
    return res.status(200).json({ message: 'Signed out' })
}