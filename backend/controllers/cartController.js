const mongoose = require('mongoose');
const Cart = require('../models/cartModel');
const Food = require('../models/foodModel');

const recalculate = (cart) => {
  cart.subtotal = Math.round(cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0) * 100) / 100;
  return cart;
};
const validQuantity = (value) => Number.isInteger(Number(value)) && Number(value) >= 1 && Number(value) <= 99;
const ownedCart = (req) => Cart.findOne({ userId: req.user.userId });

exports.getCart = async (req, res, next) => {
  try {
    const cart = await ownedCart(req);
    if (!cart) return res.json({ success: true, data: { userId: req.user.userId, items: [], subtotal: 0 } });
    await cart.populate('items.foodId');
    res.json({ success: true, data: cart });
  } catch (error) { next(error); }
};

exports.addItem = async (req, res, next) => {
  try {
    const { foodId, notes = '' } = req.body;
    const quantity = Number(req.body.quantity ?? 1);
    if (!mongoose.isValidObjectId(foodId)) return res.status(400).json({ success: false, message: 'A valid foodId is required' });
    if (!validQuantity(quantity)) return res.status(400).json({ success: false, message: 'Quantity must be an integer between 1 and 99' });
    if (typeof notes !== 'string' || notes.length > 200) return res.status(400).json({ success: false, message: 'Notes must be 200 characters or fewer' });
    const food = await Food.findById(foodId);
    if (!food || !food.available) return res.status(400).json({ success: false, message: 'Food item is unavailable' });
    let cart = await ownedCart(req);
    if (!cart) cart = new Cart({ userId: req.user.userId, items: [] });
    const item = cart.items.find((line) => line.foodId.toString() === food._id.toString());
    if (item) {
      if (item.quantity + quantity > 99) return res.status(400).json({ success: false, message: 'Maximum quantity per item is 99' });
      item.quantity += quantity;
      item.price = food.price;
      item.name = food.name;
      if (notes) item.notes = notes;
    } else {
      cart.items.push({ foodId: food._id, quantity, price: food.price, name: food.name, notes });
    }
    recalculate(cart);
    await cart.save();
    await cart.populate('items.foodId');
    res.status(201).json({ success: true, data: cart });
  } catch (error) { next(error); }
};

exports.updateItem = async (req, res, next) => {
  try {
    const quantity = Number(req.body.quantity);
    if (!validQuantity(quantity)) return res.status(400).json({ success: false, message: 'Quantity must be an integer between 1 and 99' });
    if (req.body.notes !== undefined && (typeof req.body.notes !== 'string' || req.body.notes.length > 200)) {
      return res.status(400).json({ success: false, message: 'Notes must be 200 characters or fewer' });
    }
    const cart = await ownedCart(req);
    if (!cart) return res.status(404).json({ success: false, message: 'Cart not found' });
    const item = cart.items.id(req.params.itemId);
    if (!item) return res.status(404).json({ success: false, message: 'Cart item not found' });
    const food = await Food.findById(item.foodId);
    if (!food || !food.available) return res.status(409).json({ success: false, message: 'This food item is no longer available' });
    item.quantity = quantity;
    item.price = food.price;
    item.name = food.name;
    if (req.body.notes !== undefined) item.notes = req.body.notes;
    recalculate(cart);
    await cart.save();
    await cart.populate('items.foodId');
    res.json({ success: true, data: cart });
  } catch (error) { next(error); }
};

exports.removeItem = async (req, res, next) => {
  try {
    const cart = await ownedCart(req);
    if (!cart) return res.status(404).json({ success: false, message: 'Cart not found' });
    const item = cart.items.id(req.params.itemId);
    if (!item) return res.status(404).json({ success: false, message: 'Cart item not found' });
    item.deleteOne();
    recalculate(cart);
    await cart.save();
    await cart.populate('items.foodId');
    res.json({ success: true, data: cart });
  } catch (error) { next(error); }
};

exports.clearCart = async (req, res, next) => {
  try {
    await Cart.findOneAndUpdate({ userId: req.user.userId }, { $set: { items: [], subtotal: 0 } }, { upsert: true, new: true, setDefaultsOnInsert: true });
    res.json({ success: true, message: 'Cart cleared', data: { items: [], subtotal: 0 } });
  } catch (error) { next(error); }
};
