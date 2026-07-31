const jwt = require('jsonwebtoken');
const User = require('../models/usersModel');
const { signupSchema, signinSchema } = require('../middlewares/validator');
const { doHash, doHashValidation } = require('../utils/hashing');
const makeToken = (user) => jwt.sign({ userId: user._id, email: user.email }, process.env.TOKEN_SECRET, { expiresIn: '8h' });
exports.signup = async (req, res, next) => { try {
  const { error, value } = signupSchema.validate(req.body); if (error) return res.status(400).json({ success:false, message:error.details[0].message });
  if (await User.findOne({ email:value.email })) return res.status(409).json({ success:false, message:'Email already in use' });
  const user = await User.create({ ...value, password: await doHash(value.password) }); const token = makeToken(user);
  res.status(201).json({ success:true, message:'Account created', token, data:{ id:user._id, name:user.name, email:user.email } });
} catch(e){ next(e); } };
exports.signin = async (req, res, next) => { try {
  const { error, value } = signinSchema.validate(req.body); if (error) return res.status(400).json({ success:false, message:error.details[0].message });
  const user = await User.findOne({ email:value.email }).select('+password'); if (!user || !(await doHashValidation(value.password,user.password))) return res.status(401).json({ success:false, message:'Invalid credentials' });
  const token = makeToken(user); res.cookie('Authorization', `Bearer ${token}`, { httpOnly:true, sameSite:'lax', secure:process.env.NODE_ENV==='production', maxAge:8*60*60*1000 }).json({ success:true, token, data:{ id:user._id, name:user.name, email:user.email } });
} catch(e){ next(e); } };
exports.signout = (req,res) => res.clearCookie('Authorization').json({ success:true, message:'Logged out' });
exports.me = async (req,res,next) => { try { const user=await User.findById(req.user.userId); if(!user) return res.status(404).json({success:false,message:'User not found'}); res.json({success:true,data:user}); } catch(e){next(e);} };
exports.updateProfile = async (req,res,next) => { try { const allowed=['name','phone','avatarUrl','deliveryAddress']; const changes={}; allowed.forEach(k=>{if(req.body[k]!==undefined)changes[k]=req.body[k]}); const user=await User.findByIdAndUpdate(req.user.userId,changes,{new:true,runValidators:true}); res.json({success:true,message:'Profile updated',data:user}); } catch(e){next(e);} };
