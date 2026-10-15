const mongoose=require('mongoose');
const trackingSchema=new mongoose.Schema({
 orderId:{type:mongoose.Schema.Types.ObjectId,ref:'Order',required:true,index:true},
 droneId:{type:mongoose.Schema.Types.ObjectId,ref:'Drone'},status:String,latitude:Number,longitude:Number,
 batteryLevel:{type:Number,min:0,max:100},speed:Number,altitude:Number,timestamp:{type:Date,default:Date.now,index:true}
},{timestamps:true});
trackingSchema.index({orderId:1,timestamp:-1});
module.exports=mongoose.model('Tracking',trackingSchema);
