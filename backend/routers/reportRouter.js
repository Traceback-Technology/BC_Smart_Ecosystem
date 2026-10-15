const router=require('express').Router(),c=require('../controllers/reportController'),{identifier}=require('../middlewares/identification'),{requireRoles}=require('../middlewares/role');
router.use(identifier,requireRoles('admin'));router.get('/orders',c.ordersReport);router.get('/revenue',c.revenueReport);router.get('/users',c.usersReport);module.exports=router;
