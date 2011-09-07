
var mongoose = require('mongoose'),
    mongo_uri = process.env.MONGOLAB_URI || 'mongodb://localhost/db',
    utils = require('./utils'),
    wordUnderscoreWordPattern = /\w+_\w+/,
    eduEmailPattern = /\.edu$/,
    Errors = {
      CampusNotReadyYet: new Error("Campus not ready"),
      NotEduAddress: new Error("Not an .edu address"),
      InvalidEmailAddressForDomain: new Error("Invalid email address for domain.")
    };

require("mongoose-types").loadTypes(mongoose, 'email');

var User = new mongoose.Schema({
  email: { type: mongoose.SchemaTypes.Email, required: true, index: { unique: true, sparse: true } },
  handle: String,
  salt: String,
  password: String,
  activation_code: String,
  login_allowed: {type: Boolean, default: true}
});

User.methods.hashed = function(msg) {
  return utils.hash(msg, this.salt);
};

User.methods.setPassword = function(password) {
  this.salt = utils.randomString(8);
  this.password = this.hashed(password);
};

User.statics.authenticate = function(email, password, fn) {
  this.findOne({ email: email }, function(err, user) {
    if (!user) return fn(new Error('cannot find user'));
    if (this.password === this.hashed(password)) return fn(null, user);
    fn(new Error('invalid password'));
  });
};

var acceptAll = function() { return true };
var acceptList = function(users) { 
  return function(user) {
    for (var i = 0; i < users.length; i++) {
      if (user == users[i]) {
        return true;
      }
    }
    return false;
  }
};

var emailDomains = {
  'campusch.at': acceptAll,
  'bentley.edu': function(user) { return wordUnderscoreWordPattern.test(user); }
};

if (process.env.INLUDE_TUFTS_ALUMNI) {
  emailDomains['alumni.tufts.edu'] = acceptList(process.env.TUFTS_USERS.split(','));
}

// Check to see if they are valid emails
User.pre('save', function(next) {
  var parts = this.email.split('@');
  if (emailDomains[parts[1]]) {
    if (emailDomains[parts[1]](parts[0])) {
      return next();
    }
    return next(Errors.InvalidEmailAddressForDomain());
  }
  var error = eduEmailPattern.test(parts[1]) ? Errors.CampusNotReadyYet : Errors.NotEduAddress;
  return next(error);
});

mongoose.model('User', User);

var db = mongoose.connect(mongo_uri);
exports.User = mongoose.model('User');
exports.Errors = Errors;

