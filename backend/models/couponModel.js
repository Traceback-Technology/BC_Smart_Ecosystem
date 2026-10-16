const mongoose=require('mongoose');
const couponSchema=new mongoose.Schema({
 code:{type:String,required:true,unique:true,uppercase:true,trim:true,index:true},
 description:String,type:{type:String,enum:['percentage','fixed'],default:'percentage'},
 value:{type:Number,required:true,min:0},minOrderAmount:{type:Number,default:0},maxDiscount:Number,
 usageLimit:Number,usedCount:{type:Number,default:0},active:{type:Boolean,default:true},
 expiresAt:Date
},{timestamps:true});
module.exports=mongoose.model('Coupon',couponSchema);
