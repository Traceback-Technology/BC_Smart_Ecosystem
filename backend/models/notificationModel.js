const mongoose=require('mongoose');
const notificationSchema=new mongoose.Schema({
 userId:{type:mongoose.Schema.Types.ObjectId,ref:'User',required:true,index:true},
 title:{type:String,required:true},message:{type:String,required:true},
 type:{type:String,enum:['order','promotion','system','payment','drone'],default:'system'},
 isRead:{type:Boolean,default:false,index:true},metadata:mongoose.Schema.Types.Mixed
},{timestamps:true});
module.exports=mongoose.model('Notification',notificationSchema);
