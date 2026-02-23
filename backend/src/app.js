require('dotenv').config();
const express = require('express');
const cors = require('cors');
const app = express();
const morgan = require('morgan');

app.use(morgan('dev'));

app.use(cors());
app.use(express.json());

const userRoutes = require('./routes/user.routes');
const taskRoutes = require('./routes/task.routes');
const authRoutes = require('./routes/auth.routes');
app.use('/users', userRoutes);
app.use('/tasks', taskRoutes);
app.use('/auth', authRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(3000, () => {
  console.log('API running on port 3000');
});