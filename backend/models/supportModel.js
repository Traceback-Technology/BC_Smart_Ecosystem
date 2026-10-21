const mongoose=require('mongoose');
const supportSchema=new mongoose.Schema({
 userId:{type:mongoose.Schema.Types.ObjectId,ref:'User',required:true,index:true},
 subject:{type:String,required:true},message:{type:String,required:true},
 status:{type:String,enum:['open','in_progress','resolved','closed'],default:'open',index:true},
 priority:{type:String,enum:['low','medium','high'],default:'medium'},messages:[{sender:String,message:String,createdAt:{type:Date,default:Date.now}}]
},{timestamps:true});
module.exports=mongoose.model('SupportTicket',supportSchema);
