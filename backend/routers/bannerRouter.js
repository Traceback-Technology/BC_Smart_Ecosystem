const router=require('express').Router(),c=require('../controllers/bannerController'),{identifier}=require('../middlewares/identification'),{requireRoles}=require('../middlewares/role');
router.get('/',c.getBanners);router.use(identifier,requireRoles('admin'));router.post('/',c.createBanner);router.patch('/:id',c.updateBanner);router.delete('/:id',c.deleteBanner);module.exports=router;
