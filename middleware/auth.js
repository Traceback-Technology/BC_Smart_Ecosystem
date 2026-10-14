const { verifyToken } = require('../utils/token');
const User = require('../models/User');

const unauthorized = (res) =>
    res.status(401).json({ message: 'Authentication required' });

//Header first (API clients), cookie as fallback
function extractToken(req) {
    const header = req.headers.authorization;
    if (header && header.startsWith('Bearer ')) return header.slice(7).trim();
    if (req.cookies && req.cookies.token) return req.cookies.token;
    return null;

}

// authenticate answers "who is this request from?" and attaches the answer to req.auth
function authenticate(req, res, next) {
    const token = extractToken(req);
    if (!token) return unauthorized(res);

    let payload;
    try {
        payload = verifyToken(token); // throws if forged or or expired
    } catch(err) {
        return unauthorized(res);
    }

    if (payload.isGuest === true && payload.sub && !payload.role) {
        req.auth = { type: 'guest', id: payload.sub };
    }
    else if (payload.sub && payload.email && payload.role) {
        req.auth = { type: 'user', id: payload.sub, email: payload.email, role: payload.role };
    } else {
        return unauthorized(res);
    }

    next();
}

// Everyday role check: trusts the role inside the token (no DB hit)
const requireRole = (...roles)=>(req, res, next) =>{
    if (req.auth?.type !== 'user' || !roles.includes(req.auth.role)){
        return res.status(403).json({message: 'Forbidden'});
    }
    next();
};

// Sensitive actions: re-read the role from the account's current record
const requireRoleFromDb = (...roles) => async (req, res, next)=>{
    try{
        if (req.auth?.type !== 'user') return res.status(403).json({ message: 'Forbidden' });
        const user = await User.findById(req.auth.id).select('role');
        if (!user || !roles.includes(user.role)){
            return res.status(403).json({message: 'Forbidden'});
        }

        req.auth.role = user.role; // use the fresh value from here on
        next();
    }catch(err){
        next(err);
    }
};

module.exports = {authenticate, requireRole, requireRoleFromDb};