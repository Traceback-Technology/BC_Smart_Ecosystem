const router=require('express').Router(); const c=require('../controllers/reviewController'); const {identifier}=require('../middleware/identification');
router.get('/',c.getReviews); router.post('/',identifier,c.createReview); router.put('/:id',identifier,c.updateReview); router.delete('/:id',identifier,c.deleteReview); module.exports=router;
