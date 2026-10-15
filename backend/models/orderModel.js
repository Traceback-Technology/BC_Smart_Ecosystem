const mongoose=require('mongoose');
const orderSchema=new mongoose.Schema({
  orderNumber:{type:String,unique:true,required:true,index:true},
  userId:{type:mongoose.Schema.Types.ObjectId,ref:'User',required:true,index:true},
  items:[{foodId:{type:mongoose.Schema.Types.ObjectId,ref:'Food',required:true},name:String,price:Number,quantity:{type:Number,min:1,required:true},notes:String}],
  subtotal:{type:Number,required:true},serviceFee:{type:Number,default:0},deliveryFee:{type:Number,default:0},discount:{type:Number,default:0},
  total:{type:Number,required:true},paymentId:{type:mongoose.Schema.Types.ObjectId,ref:'Payment'},
  stripePaymentIntentId:String,
  deliveryType:{type:String,enum:['pickup','drone'],default:'pickup',index:true},
  deliveryAddress:{type:String,required:true},deliveryNotes:String,
  couponCode:String,routeId:{type:mongoose.Schema.Types.ObjectId,ref:'Route'},
  droneId:{type:mongoose.Schema.Types.ObjectId,ref:'Drone'},
  status:{type:String,enum:['pending','confirmed','preparing','ready','drone_assigned','drone_launched','out_for_delivery','delivered','cancelled'],default:'pending',index:true},
  estimatedArrival:Date,
  tracking:{distanceKm:{type:Number,default:0.8},minutesAway:{type:Number,default:8},routeLabel:{type:String,default:'Fast Route'},courierLat:Number,courierLng:Number}
},{timestamps:true});
module.exports=mongoose.model('Order',orderSchema);
