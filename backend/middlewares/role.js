const User = require('../models/usersModel');

exports.requireRoles = (...roles) => async (req, res, next) => {
  try {
    if (!req.user?.userId) return res.status(401).json({success:false,message:'Unauthorized'});
    const user = await User.findById(req.user.userId).select('role');
    if (!user) return res.status(401).json({success:false,message:'User not found'});
    if (!roles.includes(user.role)) return res.status(403).json({success:false,message:'Insufficient permissions'});
    req.currentUser = user;
    next();
  } catch (e) { next(e); }
};
