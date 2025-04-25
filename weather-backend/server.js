require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const Weather = require('./models/Weather');

const app = express();
app.use(cors());
app.use(express.json());

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => console.log("MongoDB connected"))
  .catch(err => console.error("MongoDB connection error:", err));

// GET /ndrbrd?landskap=xxx&station=yyy
// app.get('/weather', async (req, res) => {
//   const { landskap, station } = req.query;
//   let query = {};
  
//   if (landskap) query.Landskap = new RegExp(landskap, 'i');
//   if (station) query.Station = new RegExp(station, 'i');

//   try {
//     const data = await Weather.find(query).limit(10000);
//   } catch (err) {
//     res.status(500).json({ error: 'Failed to fetch data' });
//   }
// });
app.get('/weather', async (req, res) => {
  const { landskap, station } = req.query;
  let query = {};
  
  if (landskap) query.Landskap = new RegExp(landskap, 'i');
  if (station) query.Station = new RegExp(station, 'i');

  try {
    const data = await Weather.find(query).limit(10000);
    res.json(data);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch data' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
