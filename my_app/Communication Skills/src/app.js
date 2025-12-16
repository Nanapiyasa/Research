const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const http = require('http');
const socketIO = require('socket.io');
require('dotenv').config();

const chatbotRoutes = require('./api/routes/chatbot.routes');
const progressRoutes = require('./api/routes/progress.routes');
const scenarioRoutes = require('./api/routes/scenario.routes');
const userRoutes = require('./api/routes/user.routes');
const assessmentRoutes = require('./api/routes/assessment.routes');

const errorHandler = require('./api/middlewares/errorHandler.middleware');
const logger = require('./utils/logger');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: process.env.FRONTEND_URL || 'http://localhost:3000',
    methods: ['GET', 'POST']
  }
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Database connection
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => logger.info('MongoDB connected successfully'))
.catch(err => logger.error('MongoDB connection error:', err));

// Routes
app.use('/api/chatbot', chatbotRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/scenarios', scenarioRoutes);
app.use('/api/users', userRoutes);
app.use('/api/assessments', assessmentRoutes);

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date() });
});

// Socket.IO for real-time chat
io.on('connection', (socket) => {
  logger.info(`User connected: ${socket.id}`);

  socket.on('chat_message', async (data) => {
    // Handle real-time chat messages
    const response = await processChatMessage(data);
    socket.emit('bot_response', response);
  });

  socket.on('disconnect', () => {
    logger.info(`User disconnected: ${socket.id}`);
  });
});

// Error handling
app.use(errorHandler);

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`);
});

module.exports = { app, io };