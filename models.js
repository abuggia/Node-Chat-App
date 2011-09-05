
var mongoose = require('mongoose'),
    mongo_uri = process.env.MONGOLAB_URI || 'mongodb://localhost/db',
    utils = require('./utils');

require("mongoose-types").loadTypes(mongoose, 'email');

var User = new mongoose.Schema({
  email: mongoose.SchemaTypes.Email,
  handle: String,
  salt: String,
  password: String
});

User.methods.hashed = function(msg) {
  return utils.hash(msg, this.salt);
};

User.methods.setPassword = function(password) {
  this.salt = utils.randomString(8);
  this.password = this.hashed(password);
};

User.methods.isCorrectPassword = function(password) {
  return this.password === this.hashed(password);
};

User.statics.authenticate = function(email, password, next) {
  User.findOne({ email: email }, function(err, user) {
    if (!user) return next(new Error('cannot find user'));
    if (user.isCorrectPassword(password)) return (null, user);
    next(new Error('invalid password'));
  });
};

var acceptedDomains = ['bently.edu', 'alumni.tufts.edu']

mongoose.model('User', User);

var db = mongoose.connect(mongo_uri);
exports.User = mongoose.model('User');

