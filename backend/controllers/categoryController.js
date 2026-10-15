const Category = require('../models/categoryModel');
const { categorySchema } = require('../middlewares/validator');

exports.getCategories = async (req, res, next) => {
  try {
    const categories = await Category.find().sort({ name: 1 });
    res.json({ success: true, count: categories.length, data: categories });
  } catch (e) { next(e); }
};

exports.getCategory = async (req, res, next) => {
  try {
    const category = await Category.findById(req.params.id);
    if (!category) return res.status(404).json({ success: false, message: 'Category not found' });
    res.json({ success: true, data: category });
  } catch (e) { next(e); }
};

exports.createCategory = async (req, res, next) => {
  try {
    const { error, value } = categorySchema.validate(req.body);
    if (error) return res.status(400).json({ success: false, message: error.details[0].message });
    if (await Category.findOne({ name: value.name })) return res.status(409).json({ success: false, message: 'Category already exists' });
    const category = await Category.create(value);
    res.status(201).json({ success: true, data: category });
  } catch (e) { next(e); }
};

exports.updateCategory = async (req, res, next) => {
  try {
    const { error, value } = categorySchema.validate(req.body);
    if (error) return res.status(400).json({ success: false, message: error.details[0].message });
    const category = await Category.findByIdAndUpdate(req.params.id, value, { new: true, runValidators: true });
    if (!category) return res.status(404).json({ success: false, message: 'Category not found' });
    res.json({ success: true, data: category });
  } catch (e) { next(e); }
};

exports.deleteCategory = async (req, res, next) => {
  try {
    const category = await Category.findByIdAndDelete(req.params.id);
    if (!category) return res.status(404).json({ success: false, message: 'Category not found' });
    res.json({ success: true, message: 'Category deleted' });
  } catch (e) { next(e); }
};
