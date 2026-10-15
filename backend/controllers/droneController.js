const Drone=require('../models/droneModel'),Order=require('../models/orderModel'),Payment=require('../models/paymentModel');
exports.getDrones=async(req,res,next)=>{try{const data=await Drone.find().sort({status:1,droneName:1});res.json({success:true,data})}catch(e){next(e)}};
exports.getDrone=async(req,res,next)=>{try{const d=await Drone.findById(req.params.id);if(!d)return res.status(404).json({success:false,message:'Drone not found'});res.json({success:true,data:d})}catch(e){next(e)}};
exports.createDrone=async(req,res,next)=>{try{const d=await Drone.create(req.body);res.status(201).json({success:true,data:d})}catch(e){next(e)}};
exports.updateDrone=async(req,res,next)=>{try{const d=await Drone.findByIdAndUpdate(req.params.id,req.body,{new:true,runValidators:true});if(!d)return res.status(404).json({success:false,message:'Drone not found'});res.json({success:true,data:d})}catch(e){next(e)}};
exports.deleteDrone=async(req,res,next)=>{try{const d=await Drone.findByIdAndDelete(req.params.id);if(!d)return res.status(404).json({success:false,message:'Drone not found'});res.json({success:true,message:'Drone deleted'})}catch(e){next(e)}};
exports.assignDrone=async(req,res,next)=>{try{
  const order=await Order.findById(req.params.orderId);
  if(!order)return res.status(404).json({success:false,message:'Order not found'});
  if(order.deliveryType!=='drone')return res.status(409).json({success:false,message:'Only drone-delivery orders can be assigned a drone'});
  if(!['ready'].includes(order.status))return res.status(409).json({success:false,message:'Order must be ready before drone assignment'});
  const payment=await Payment.findOne({orderId:order._id});
  if(payment?.status!=='succeeded')return res.status(409).json({success:false,message:'Order must have a successful payment before drone assignment'});
  if(order.droneId)return res.status(409).json({success:false,message:'A drone is already assigned to this order'});
  const drone=await Drone.findOneAndUpdate({_id:req.body.droneId,status:'available'},{status:'assigned'},{new:true});
  if(!drone)return res.status(409).json({success:false,message:'Drone unavailable'});
  order.droneId=drone._id;order.status='drone_assigned';
  try{await order.save();}catch(error){drone.status='available';await drone.save();throw error;}
  res.json({success:true,data:{order,drone}});
}catch(error){next(error)}};
