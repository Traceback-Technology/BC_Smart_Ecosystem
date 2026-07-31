const Joi = require('joi');
exports.signupSchema = Joi.object({ name: Joi.string().min(2).max(60).default('User'), email: Joi.string().email().required(), password: Joi.string().min(8).pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$/).required() });
exports.signinSchema = Joi.object({ email: Joi.string().email().required(), password: Joi.string().required() });
exports.foodSchema = Joi.object({ name: Joi.string().min(2).max(80).required(), description: Joi.string().min(3).max(500).required(), category: Joi.string().valid('Burgers','Fries','Pizza','Drinks','Tacos','Bowls','Other').required(), price: Joi.number().min(0).required(), imageUrl: Joi.string().uri().allow(''), available: Joi.boolean(), popular: Joi.boolean() });
exports.orderSchema = Joi.object({ items: Joi.array().items(Joi.object({ foodId: Joi.string().required(), quantity: Joi.number().integer().min(1).required(), notes: Joi.string().max(200).allow('') })).min(1).required(), deliveryAddress: Joi.string().min(5).required(), deliveryNotes: Joi.string().max(300).allow('') });
exports.routeSchema = Joi.object({ origin: Joi.string().required(), destination: Joi.string().required() });
exports.categorySchema = Joi.object({ name: Joi.string().min(2).max(60).required() });
exports.reviewSchema = Joi.object({ foodId: Joi.string().required(), rating: Joi.number().integer().min(1).max(5).required(), comment: Joi.string().max(500).allow('') });
