require('dotenv').config(); // Load environment variables from .env file

const express = require('express');
const cookieParser = require('cookie-parser');
const connectDB = require('./config/db');
const authRoutes = require('./routes/authRoutes');

const app = express();
app.use(express.json()); //makes req.body work
app.use(cookieParser()); //makes req.cookies work
app.use('/api/', authRoutes);

//catches anything controllers pass to next(err)
app.use((err, req, res, next) => {
    console.error(err);
    res.status(500).json({ message: 'Something went wrong' });
});

const PORT = process.env.PORT || 3000;
connectDB().then(() => app.listen(PORT, () => console.log(`API running on port ${PORT}`)));