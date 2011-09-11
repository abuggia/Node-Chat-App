_ = require('underscore')
mongoose = require('mongoose')
require("mongoose-types").loadTypes mongoose, 'email'
mongo_uri = process.env.MONGOLAB_URI || 'mongodb://localhost/db'
wordUnderscoreWordPattern = /\w+_\w+/
eduPattern = /\.edu$/
email = require("./email.coffee") 
Errors =
   CampusNotReadyYet: new Error("Campus not ready")
   NotEduAddress: new Error("Not an .edu address")
   InvalidEmailAddressForDomain: new Error("Invalid email address for domain.")

randomString = (length) ->
  arr = [ chars.charAt(Math.floor(Math.random() * (chars.length - 1))) for [1..length] ]
  arr.join ''


User = new mongoose.Schema {
  email: { type: mongoose.SchemaTypes.Email, required: true, index: { unique: true, sparse: true } },
  handle: String,
  salt: String,
  password: String,
  activation_code: String,
  login_allowed: {type: Boolean, default: true}
}

User.methods.hashed = (msg) ->
  return crypto.createHmac('sha256', this.salt).update(msg).digest('hex')


User.methods.setPassword = (password) ->
  this.salt = utils.randomString(8);
  this.password = this.hashed(password)

User.statics.authenticate = (email, password, fn) ->
  this.findOne { email: email }, (err, user) ->
    if !user then fn(new Error('cannot find user'))
    else if this.password is this.hashed(password) then fn(null, user)
    else fn(new Error('invalid password'))

acceptList = (users) -> (user) -> _(users).any(user)
emailDomains = {
  'campusch.at': -> true
  'bentley.edu': (user) -> wordUnderscoreWordPattern.test user
  'alumni.tufts.edu': (user) -> if process.env.INLUDE_TUFTS_ALUMNI acceptList(process.env.TUFTS_USERS.split(','))(user) else false
};

User.pre 'save', (next) ->
  [name, domain] = this.email.split '@'

  if emailDomains[domain]
    if emailDomains[domain](name) then next() else next Errors.InvalidEmailAddressForDomain
  else
    next(if eduPattern.test(domain) then Errors.CampusNotReadyYet else Errors.NotEduAddress)


User.pre 'save', (next) -> this.activation_code = randomString(12)

mongoose.model 'User', User

db = mongoose.connect mongo_uri, (err) ->
  if err
    console.log "PROBLEM CONNECTING TO MONGO: " + err

module.exports.User = mongoose.model('User')
module.exports.Errors = Errors

