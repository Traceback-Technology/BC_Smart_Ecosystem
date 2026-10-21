const router=require('express').Router(),c=require('../controllers/favouriteController'),{identifier}=require('../middlewares/identification');
router.use(identifier);router.get('/',c.getFavourites);router.post('/:foodId',c.addFavourite);router.post('/:foodId/toggle',c.toggleFavourite);router.delete('/:foodId',c.removeFavourite);module.exports=router;
