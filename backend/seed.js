const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const User = require('./models/usersModel');
const Category = require('./models/categoryModel');
const Food = require('./models/foodModel');
const Coupon = require('./models/couponModel');
const Banner = require('./models/bannerModel');
const Drone = require('./models/droneModel');
const Order = require('./models/orderModel');
const Route = require('./models/routeModel');
const Tracking = require('./models/trackingModel');
const Payment = require('./models/paymentModel');
const Review = require('./models/reviewModel');
const Notification = require('./models/notificationModel');
const Activity = require('./models/activityModel');
const Cart = require('./models/cartModel');
const Support = require('./models/supportModel');

async function run() {
  await mongoose.connect(process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/bc_eats');
  console.log('Connected to MongoDB');

  await Promise.all([
    User.deleteMany({}), Category.deleteMany({}), Food.deleteMany({}), Coupon.deleteMany({}),
    Banner.deleteMany({}), Drone.deleteMany({}), Order.deleteMany({}), Route.deleteMany({}),
    Tracking.deleteMany({}), Payment.deleteMany({}), Review.deleteMany({}), Notification.deleteMany({}),
    Activity.deleteMany({}), Cart.deleteMany({}), Support.deleteMany({})
  ]);

  const password = await bcrypt.hash('Password1', 12);
  const [admin, restaurant, customer, droneOperator] = await User.create([
    { name: 'BC Eats Admin', fullName: 'BC Eats Admin', email: 'admin@bceats.test', password, role: 'admin', verified: true, phone: '0120000001' },
    { name: 'Campus Kitchen', fullName: 'Campus Kitchen', email: 'restaurant@bceats.test', password, role: 'restaurant', verified: true, phone: '0120000002' },
    { name: 'Test Student', fullName: 'Test Student', email: 'student@bceats.test', password, role: 'customer', verified: true, phone: '0820000003', deliveryAddress: 'Belgium Campus Pretoria', addresses: [{ label: 'Campus', address: 'Belgium Campus Pretoria', latitude: -25.7479, longitude: 28.2293, isDefault: true }] },
    { name: 'Drone Operator', fullName: 'Drone Operator', email: 'drone@bceats.test', password, role: 'drone_operator', verified: true, phone: '0820000004' }
  ]);

  const categories = await Category.create([
    { name: 'Burgers' }, { name: 'Pizza' }, { name: 'Healthy' }, { name: 'Drinks' }, { name: 'Desserts' }
  ]);

  const foods = await Food.create([
    { name: 'Classic Beef Burger', description: 'Beef patty with lettuce, tomato, cheese and sauce.', category: 'Burgers', ingredients: ['beef', 'lettuce', 'tomato', 'cheese', 'bun'], nutritionInfo: { calories: 650, protein: 32, carbs: 55, fat: 31 }, price: 79.99, available: true, popular: true, imageUrl: 'https://example.com/burger.jpg' },
    { name: 'Chicken Pizza', description: 'Chicken, mozzarella, tomato and herbs on a crispy base.', category: 'Pizza', ingredients: ['chicken', 'mozzarella', 'tomato', 'herbs'], nutritionInfo: { calories: 720, protein: 35, carbs: 78, fat: 28 }, price: 119.99, available: true, popular: true, imageUrl: 'https://example.com/pizza.jpg' },
    { name: 'Grilled Chicken Salad', description: 'Fresh greens with grilled chicken and light dressing.', category: 'Healthy', ingredients: ['chicken', 'lettuce', 'cucumber', 'tomato'], nutritionInfo: { calories: 410, protein: 38, carbs: 18, fat: 17 }, price: 89.99, available: true, popular: false, imageUrl: 'https://example.com/salad.jpg' },
    { name: 'Sparkling Water', description: 'Chilled sparkling water.', category: 'Drinks', ingredients: ['water'], nutritionInfo: { calories: 0, protein: 0, carbs: 0, fat: 0 }, price: 19.99, available: true, popular: false, imageUrl: 'https://example.com/water.jpg' },
    { name: 'Chocolate Brownie', description: 'Warm chocolate brownie with a rich chocolate centre.', category: 'Desserts', ingredients: ['cocoa', 'flour', 'sugar', 'butter'], nutritionInfo: { calories: 390, protein: 5, carbs: 48, fat: 20 }, price: 49.99, available: true, popular: true, imageUrl: 'https://example.com/brownie.jpg' }
  ]);

  const coupon = await Coupon.create({ code: 'WELCOME10', description: '10% off orders over R100', type: 'percentage', value: 10, minOrderAmount: 100, maxDiscount: 50, usageLimit: 100, active: true, expiresAt: new Date(Date.now() + 30 * 86400000) });
  const banner = await Banner.create({ title: 'Welcome to BC Eats', description: '10% off your first qualifying order.', imageUrl: 'https://example.com/banner.jpg', link: '/menu', active: true, priority: 10 });
  const [drone1, drone2] = await Drone.create([
    { droneName: 'BC Drone Alpha', serialNumber: 'BC-DRONE-001', battery: 94, status: 'available', currentLocation: { latitude: -25.7479, longitude: 28.2293 }, speed: 0, altitude: 0, healthStatus: 'healthy', maintenanceDate: new Date(Date.now() + 30 * 86400000) },
    { droneName: 'BC Drone Beta', serialNumber: 'BC-DRONE-002', battery: 76, status: 'charging', currentLocation: { latitude: -25.75, longitude: 28.23 }, speed: 0, altitude: 0, healthStatus: 'healthy', maintenanceDate: new Date(Date.now() + 45 * 86400000) }
  ]);

  const order = await Order.create({
    orderNumber: 'BC-DEMO-001', userId: customer._id,
    items: [{ foodId: foods[0]._id, name: foods[0].name, price: foods[0].price, quantity: 2, notes: 'Extra cheese' }, { foodId: foods[3]._id, name: foods[3].name, price: foods[3].price, quantity: 1 }],
    subtotal: 179.97, deliveryFee: 0, discount: 0, total: 179.97,
    deliveryAddress: 'Belgium Campus Pretoria', deliveryNotes: 'Call when outside', deliveryType: 'drone', status: 'drone_launched',
    estimatedArrival: new Date(Date.now() + 15 * 60000), tracking: { distanceKm: 1.8, minutesAway: 8, routeLabel: 'Fast Route', courierLat: -25.7485, courierLng: 28.2299 }
  });

  const route = await Route.create({
    userId: customer._id, droneId: drone1._id, orderId: order._id,
    pickupLocation: { address: 'BC Eats Kitchen', latitude: -25.7465, longitude: 28.2285 },
    destinationLocation: { address: 'Belgium Campus Pretoria', latitude: -25.7479, longitude: 28.2293 },
    origin: 'BC Eats Kitchen', destination: 'Belgium Campus Pretoria', estimatedMinutes: 8, distanceKm: 1.8,
    coordinates: [{ latitude: -25.7465, longitude: 28.2285 }, { latitude: -25.7472, longitude: 28.2290 }, { latitude: -25.7479, longitude: 28.2293 }], status: 'active'
  });
  order.routeId = route._id; order.droneId = drone1._id; await order.save();

  const payment = await Payment.create({ userId: customer._id, orderId: order._id, provider: 'stripe', amount: order.total, currency: 'zar', status: 'succeeded', metadata: { demo: true } });
  order.paymentId = payment._id; await order.save();

  await Tracking.create([
    { orderId: order._id, droneId: drone1._id, status: 'drone_launched', latitude: -25.7485, longitude: 28.2299, batteryLevel: 82, speed: 12, altitude: 30, timestamp: new Date(Date.now() - 2 * 60000) },
    { orderId: order._id, droneId: drone1._id, status: 'drone_launched', latitude: -25.7479, longitude: 28.2293, batteryLevel: 79, speed: 10, altitude: 28, timestamp: new Date() }
  ]);

  const review = await Review.create({ userId: customer._id, foodId: foods[0]._id, rating: 5, comment: 'Great burger and quick delivery.' });
  await Food.findByIdAndUpdate(foods[0]._id, { ratingAverage: 5, totalReviews: 1 });

  await Notification.create([
    { userId: customer._id, title: 'Order confirmed', message: 'Your demo order has been confirmed.', type: 'order', isRead: false, metadata: { orderId: order._id } },
    { userId: customer._id, title: 'Drone launched', message: 'Your delivery drone is on its way.', type: 'drone', isRead: false, metadata: { orderId: order._id, droneId: drone1._id } }
  ]);
  await Activity.create([{ userId: customer._id, type: 'food', title: 'Demo order BC-DEMO-001', amount: order.total, metadata: { orderId: order._id } }]);
  await Cart.create({ userId: customer._id, items: [{ foodId: foods[1]._id, quantity: 1, price: foods[1].price, name: foods[1].name, notes: 'No olives' }], subtotal: foods[1].price });
  await Support.create({ userId: customer._id, subject: 'Demo support ticket', message: 'I need help with my demo order.', priority: 'medium', messages: [{ sender: 'user', message: 'I need help with my demo order.' }] });

  console.log('\nSeed complete. Demo accounts (all use Password1):');
  console.log('admin@bceats.test / Password1');
  console.log('restaurant@bceats.test / Password1');
  console.log('student@bceats.test / Password1');
  console.log('drone@bceats.test / Password1');
  console.log('\nDemo IDs:');
  console.log(JSON.stringify({ userId: customer._id, adminId: admin._id, restaurantId: restaurant._id, droneOperatorId: droneOperator._id, foodId: foods[0]._id, foodId2: foods[1]._id, categoryId: categories[0]._id, couponId: coupon._id, bannerId: banner._id, droneId: drone1._id, droneId2: drone2._id, orderId: order._id, routeId: route._id, paymentId: payment._id, reviewId: review._id }, null, 2));
  await mongoose.disconnect();
}

run().catch(async (err) => { console.error(err); try { await mongoose.disconnect(); } catch (_) {} process.exit(1); });
