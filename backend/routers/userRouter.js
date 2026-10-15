const router=require('express').Router(),c=require('../controllers/userController'),{identifier}=require('../middlewares/identification'),{requireRoles}=require('../middlewares/role');
router.use(identifier,requireRoles('admin'));
router.get('/',c.getUsers);router.get('/:id',c.getUser);router.patch('/:id',c.updateUser);router.delete('/:id',c.deleteUser);module.exports=router;
