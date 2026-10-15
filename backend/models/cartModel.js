const mongoose=require('mongoose');
const cartSchema=new mongoose.Schema({
 userId:{type:mongoose.Schema.Types.ObjectId,ref:'User',required:true,unique:true,index:true},
 items:[{foodId:{type:mongoose.Schema.Types.ObjectId,ref:'Food',required:true},quantity:{type:Number,min:1,required:true},price:{type:Number,required:true},name:String,notes:String}],
 subtotal:{type:Number,default:0}
},{timestamps:true});
module.exports=mongoose.model('Cart',cartSchema);
