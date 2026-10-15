const mongoose=require('mongoose');
const foodSchema=new mongoose.Schema({
  name:{type:String,required:true,trim:true,index:true},
  description:{type:String,required:true,trim:true},
  category:{type:String,required:true,trim:true,index:true},
  ingredients:[String],
  nutritionInfo:{calories:Number,protein:Number,carbs:Number,fat:Number},
  imageUrl:String,image:String,
  price:{type:Number,required:true,min:0},
  available:{type:Boolean,default:true,index:true},
  popular:{type:Boolean,default:false},
  ratingAverage:{type:Number,default:0,min:0,max:5},
  totalReviews:{type:Number,default:0,min:0}
},{timestamps:true});
foodSchema.index({name:'text',description:'text',category:'text'});
module.exports=mongoose.model('Food',foodSchema);
