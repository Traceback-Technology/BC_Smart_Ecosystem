const mongoose=require('mongoose');
const bannerSchema=new mongoose.Schema({
 title:{type:String,required:true},description:String,imageUrl:String,link:String,
 active:{type:Boolean,default:true,index:true},startsAt:Date,endsAt:Date,priority:{type:Number,default:0}
},{timestamps:true});
module.exports=mongoose.model('Banner',bannerSchema);
