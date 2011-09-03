
var mongoose = require('mongoose');
var mongo_uri = process.env.MONGOLAB_URI || 'mongodb://localhost/db'

mongoose.model('User', new mongoose.Schema({
  email: String,
  handle: String,
  password: String
}));

var db = mongoose.connect(mongo_uri);

var User = mongoose.model('User');

exports.User = User
