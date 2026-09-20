const jwt = require('jsonwebtoken');
exports.identifier = (req, res, next) => {
  const raw = req.headers.authorization || req.cookies.Authorization;
  if (!raw) return res.status(401).json({ success: false, message: 'Unauthorized' });
  try {
    const token = raw.startsWith('Bearer ') ? raw.slice(7) : raw;
    req.user = jwt.verify(token, process.env.TOKEN_SECRET);
    next();
  } catch (error) { return res.status(401).json({ success: false, message: 'Invalid or expired token' }); }
};
