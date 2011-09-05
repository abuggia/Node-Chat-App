
var mongoose = require('mongoose'),
    mongo_uri = process.env.MONGOLAB_URI || 'mongodb://localhost/db'; 

require("mongoose-types").loadTypes(mongoose, 'email');

mongoose.model('User', new mongoose.Schema({
  email: mongoose.SchemaTypes.Email,
  handle: String,
  password: String
}));



var acceptedDomains = ['bently.edu', 'alumni.tufts.edu']


var db = mongoose.connect(mongo_uri);
var User = mongoose.model('User');

exports.User = User
