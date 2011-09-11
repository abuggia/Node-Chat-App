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
  voted: Boolean
  school: String
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

User.methods.isEmailExistsError = (err) ->
  err and /E11000/.test(err.message) and /email/.test(err.message)

acceptList = (users) -> (user) -> _(users).any(user)
emailDomains = {
  'campusch.at': -> true
  #'bentley.edu': (user) -> wordUnderscoreWordPattern.test user
  'alumni.tufts.edu': (user) -> if process.env.TUFTS_ALUMNI? then acceptList(process.env.TUFTS_ALUMNI.split(','))(user) else false
}

User.pre 'save', (next) -> 
  if not this.activation_code?
    this.activation_code = randomString(12)
  next()

User.pre 'save', (next) -> 
  this.activation_code = randomString(12)
  [name, domain] = this.email.split '@'
  this.school = domain
  next()

User.pre 'save', (next) ->
  [name, domain] = this.email.split '@'

  if emailDomains[domain]
    if emailDomains[domain](name) then next() else next(new errors.Forbidden())
  else if eduPattern.test(domain)
    next()
  else
    next(new errors.Forbidden())


mongoose.model 'User', User

db = mongoose.connect mongo_uri, (err) ->
  console.log "Trying to connect to mongo with uri: " + mongo_uri
  if err
    console.log "PROBLEM CONNECTING TO MONGO: " + err

module.exports.User = mongoose.model('User')

