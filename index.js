const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const mongoose = require('mongoose');
require('dotenv').config();

const authRouter = require('./routers/authRouter');
const foodRouter = require('./routers/foodRouter');
const orderRouter = require('./routers/orderRouter');
const activityRouter = require('./routers/activityRouter');
const navigationRouter = require('./routers/navigationRouter');
const categoryRouter = require('./routers/categoryRouter');
const reviewRouter = require('./routers/reviewRouter');

const app = express();
app.use(cors({ origin: process.env.CLIENT_ORIGIN || true, credentials: true }));
app.use(helmet());
app.use(cookieParser());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => res.json({ success: true, message: 'BC Eats API is running' }));
app.use('/api/users', authRouter);
app.use('/api/foods', foodRouter);
app.use('/api/orders', orderRouter);
app.use('/api/activities', activityRouter);
app.use('/api/navigation', navigationRouter);
app.use('/api/categories', categoryRouter);
app.use('/api/reviews', reviewRouter);

app.use((req, res) => res.status(404).json({ success: false, message: 'Route not found', method: req.method, path: req.originalUrl }));
app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({ success: false, message: err.message || 'Server error' });
});

const port = process.env.PORT || 8000;
mongoose.connect(process.env.MONGO_URI)
  .then(() => app.listen(port, () => console.log(`BC Eats API listening on port ${port}`)))
  .catch((err) => { console.error('Database connection error:', err.message); process.exit(1); });
