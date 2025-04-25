const mongoose = require('mongoose');

const weatherSchema = new mongoose.Schema({
  Station: String,
  Landskap: String,
  jan: Number,
  feb: Number,
  mar: Number,
  apr: Number,
  maj: Number,
  jun: Number,
  jul: Number,
  aug: Number,
  sep: Number,
  okt: Number,
  nov: Number,
  dec: Number
});

module.exports = mongoose.model('Weather', weatherSchema);
