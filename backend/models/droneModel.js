const mongoose=require('mongoose');
const droneSchema=new mongoose.Schema({
 droneName:{type:String,required:true,trim:true},serialNumber:{type:String,required:true,unique:true,index:true},
 battery:{type:Number,min:0,max:100,default:100},status:{type:String,enum:['available','assigned','in_flight','charging','maintenance','offline'],default:'available',index:true},
 currentLocation:{latitude:Number,longitude:Number},speed:{type:Number,default:0},altitude:{type:Number,default:0},
 healthStatus:{type:String,enum:['healthy','warning','critical'],default:'healthy'},maintenanceDate:Date
},{timestamps:true});
module.exports=mongoose.model('Drone',droneSchema);
