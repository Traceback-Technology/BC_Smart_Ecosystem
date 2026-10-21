const Notification=require('../models/notificationModel');
exports.getNotifications=async(req,res,next)=>{try{const limit=Math.min(Number(req.query.limit)||30,100);const data=await Notification.find({userId:req.user.userId}).sort({createdAt:-1}).limit(limit);res.json({success:true,count:data.length,data})}catch(e){next(e)}};
exports.markRead=async(req,res,next)=>{try{const n=await Notification.findOneAndUpdate({_id:req.params.id,userId:req.user.userId},{isRead:true},{new:true});if(!n)return res.status(404).json({success:false,message:'Notification not found'});res.json({success:true,data:n})}catch(e){next(e)}};
exports.markAllRead=async(req,res,next)=>{try{const r=await Notification.updateMany({userId:req.user.userId,isRead:false},{isRead:true});res.json({success:true,modifiedCount:r.modifiedCount})}catch(e){next(e)}};
exports.createNotification=async(userId,title,message,type='system',metadata={})=>Notification.create({userId,title,message,type,metadata});
