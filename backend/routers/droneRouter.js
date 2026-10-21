const router=require('express').Router(),c=require('../controllers/droneController'),{identifier}=require('../middlewares/identification'),{requireRoles}=require('../middlewares/role');
router.use(identifier,requireRoles('admin','drone_operator'));
router.get('/',c.getDrones);router.get('/:id',c.getDrone);router.post('/',requireRoles('admin'),c.createDrone);router.patch('/:id',c.updateDrone);router.delete('/:id',requireRoles('admin'),c.deleteDrone);router.post('/assign/:orderId',c.assignDrone);module.exports=router;
