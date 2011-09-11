_ = require('underscore')
mongoose = require('mongoose')
mongo_uri = process.env.MONGO_URI
errors = require('./../errors.coffee')
wordUnderscoreWordPattern = /\w+_\w+/
eduPattern = /\.edu$/
email = require("./email.coffee") 
chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz";
randomString = (length) -> [ chars.charAt(Math.floor(Math.random() * (chars.length - 1))) for [1..length] ].join ''


require("mongoose-types").loadTypes mongoose, 'email'

User = new mongoose.Schema {
  email: { type: mongoose.SchemaTypes.Email, required: true, index: { unique: true, sparse: true } }
  handle: String
  salt: String
  password: String
  activation_code: String
  login_allowed: { type: Boolean, default: true }
  vote_open_on_campus: Boolean
  vote_email_me: Boolean
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
}

User.pre 'save', (next) ->
  [name, domain] = this.email.split '@'

  if emailDomains[domain]
    if emailDomains[domain](name) then next() else next Errors.Forbidden
  else
    next(if eduPattern.test(domain) then new errors.NotReady() else new errors.Forbidden())


User.pre 'save', (next) -> 
  this.activation_code = randomString(12)
  next()

mongoose.model 'User', User

db = mongoose.connect mongo_uri, (err) ->
  console.log "Trying to connect to mongo with uri: " + mongo_uri
  if err
    console.log "PROBLEM CONNECTING TO MONGO: " + err

module.exports.User = mongoose.model('User')

