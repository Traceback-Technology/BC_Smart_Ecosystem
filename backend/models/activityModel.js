const mongoose=require('mongoose');
const activitySchema=new mongoose.Schema({
 userId:{type:mongoose.Schema.Types.ObjectId,ref:'User',required:true,index:true},
 type:{type:String,enum:['ride','food','payment','system'],required:true},title:{type:String,required:true},
 amount:{type:Number,default:0},metadata:mongoose.Schema.Types.Mixed,occurredAt:{type:Date,default:Date.now}
},{timestamps:true});
module.exports=mongoose.model('Activity',activitySchema);
