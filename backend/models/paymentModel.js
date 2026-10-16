const mongoose=require('mongoose');
const paymentSchema=new mongoose.Schema({
 userId:{type:mongoose.Schema.Types.ObjectId,ref:'User',required:true,index:true},
 orderId:{type:mongoose.Schema.Types.ObjectId,ref:'Order',required:true,index:true,unique:true},
 provider:{type:String,enum:['stripe','cash','other'],default:'stripe'},
 paymentIntentId:String,amount:{type:Number,required:true},currency:{type:String,default:'zar'},
 status:{type:String,enum:['pending','requires_action','succeeded','failed','refunded'],default:'pending',index:true},
 refundAmount:{type:Number,default:0},metadata:mongoose.Schema.Types.Mixed
},{timestamps:true});
module.exports=mongoose.model('Payment',paymentSchema);
