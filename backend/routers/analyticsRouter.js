const router=require('express').Router(),c=require('../controllers/analyticsController'),{identifier}=require('../middlewares/identification'),{requireRoles}=require('../middlewares/role');
router.use(identifier,requireRoles('admin'));router.get('/dashboard',c.dashboard);router.get('/sales',c.sales);module.exports=router;
