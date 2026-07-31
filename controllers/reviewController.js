const Review = require('../models/reviewModel');
const Food = require('../models/foodModel');
const { reviewSchema } = require('../middlewares/validator');

exports.getReviews = async (req, res, next) => {
  try {
    const filter = {};
    if (req.query.foodId) filter.foodId = req.query.foodId;
    const reviews = await Review.find(filter).sort({ createdAt: -1 });
    res.json({ success: true, count: reviews.length, data: reviews });
  } catch (e) { next(e); }
};

exports.createReview = async (req, res, next) => {
  try {
    const { error, value } = reviewSchema.validate(req.body);
    if (error) return res.status(400).json({ success: false, message: error.details[0].message });
    const food = await Food.findById(value.foodId);
    if (!food) return res.status(404).json({ success: false, message: 'Food item not found' });
    const review = await Review.create({ ...value, userId: req.user.userId });
    res.status(201).json({ success: true, data: review });
  } catch (e) { next(e); }
};

exports.updateReview = async (req, res, next) => {
  try {
    const allowed = ['rating', 'comment'];
    const changes = {};
    allowed.forEach((k) => { if (req.body[k] !== undefined) changes[k] = req.body[k]; });
    const review = await Review.findOneAndUpdate({ _id: req.params.id, userId: req.user.userId }, changes, { new: true, runValidators: true });
    if (!review) return res.status(404).json({ success: false, message: 'Review not found' });
    res.json({ success: true, data: review });
  } catch (e) { next(e); }
};

exports.deleteReview = async (req, res, next) => {
  try {
    const review = await Review.findOneAndDelete({ _id: req.params.id, userId: req.user.userId });
    if (!review) return res.status(404).json({ success: false, message: 'Review not found' });
    res.json({ success: true, message: 'Review deleted' });
  } catch (e) { next(e); }
};
