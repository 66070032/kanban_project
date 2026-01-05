require('dotenv').config();
const express = require('express');
const app = express();

app.use(express.json());

const userRoutes = require('./routes/user.routes');
app.use('/users', userRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(3000, () => {
  console.log('API running on port 3000');
  console.log(process.env.DATABASE_URL)
});