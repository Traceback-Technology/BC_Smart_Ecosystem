
 const jwt = require('jsonwebtoken');

 const SECRET = process.env.JWT_SECRET;
 if(!SECRET) throw new Error('JWT_SECRET is not set');

 const USER_EXPIRES = process.env.JWT_EXPIRES_IN || '8h';
 const GUEST_EXPIRES = process.env.JWT_GUEST_EXPIRES_IN || '7d';

 /// Registered-user session: account
///                          email
///                          role
///                          (iat/exp added automatically)

//* "sub" is the standard JWT field for "Who this is"
function makeUserToken(user){
    return jwt.sign(
        {sub: user._id.toString(), email: user.email, role: user.role},
        SECRET,
        {algorithm: 'HS256', expiresIn: USER_EXPIRES}
    )
}

// guest session: disposable id, explicitly marked as a guest, no role
function makeGuestToken(guestId){
    return jwt.sign(
        {sub: guestId, isGuest: true},
        SECRET,
        {algorithm: 'HS256', expiresIn: GUEST_EXPIRES}
    );
}

function verifyToken(token){
    // Pin the algorithm so a forged "alg: none" token never pass
    return jwt.verify(token, SECRET, {algorithms: ['HS256']});
}

module.exports = {makeUserToken, makeGuestToken, verifyToken};