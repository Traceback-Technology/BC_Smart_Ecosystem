const router=require('express').Router(); const c=require('../controllers/categoryController'); const {identifier}=require('../middlewares/identification');
router.get('/',c.getCategories); router.get('/:id',c.getCategory); router.post('/',identifier,c.createCategory); router.put('/:id',identifier,c.updateCategory); router.delete('/:id',identifier,c.deleteCategory); module.exports=router;
