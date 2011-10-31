_ = require('underscore')
mongoose = require('mongoose')
mongo_uri = process.env.MONGO_URI
errors = require('./../errors.coffee')
wordUnderscoreWordPattern = /\w+_\w+/
eduPattern = /\.edu$/
email = require("./email.coffee") 
crypto = require("crypto")
chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz"
lastPos = chars.length - 1
randomString = (length) -> ( chars.charAt(Math.floor(Math.random() * lastPos)) for [1..length] ).join('')
hashed = (msg, salt) -> 
  crypto.createHmac('sha256', salt).update(msg).digest('hex')

require("mongoose-types").loadTypes mongoose, 'email'

School = new mongoose.Schema {
  name: { type: String, required: true, index: { unique: true } }
  short: { type: String, required: true, index: { unique: true } }
  domain: String
  room: String
  available: { type: Boolean, default: false }
}

mongoose.model 'School', School

SpecialEmail = new mongoose.Schema {
  email: { type: mongoose.SchemaTypes.Email, required: true }
  school: { type: String, required: true }  # School short name
}

mongoose.model 'SpecialEmail', SpecialEmail 

User = new mongoose.Schema {
  email: { type: mongoose.SchemaTypes.Email, required: true, index: { unique: true, sparse: true } }
  handle: String
  salt: String
  password: String
  activation_code: String
  state: String
  login_allowed: { type: Boolean, default: true }
  vote_open_on_campus: Boolean
  vote_email_me: Boolean
  voted: Boolean
  school: String
  start_room: String
}

User.methods.setPassword = (password) ->
  this.salt = randomString(8);
  this.password = hashed(password, this.salt)

User.methods.active = -> this.state is 'active'

User.methods.safe_json = -> 
  { email: this.email, active: this.active(), start_room: this.start_room, voted: this.voted, handle: this.handle } 

User.statics.authenticate = (email, password, fn) ->
  this.findOne { email: email }, (err, user) ->
    if !user then fn(new Error('cannot find user'))
    else if user.password is hashed(password, user.salt) then fn(null, user)
    else fn(new Error('invalid password'))

User.methods.isEmailExistsError = (err) ->
  err and /E11000/.test(err.message) and /email/.test(err.message)

User.methods.canAccessRoom = (room) ->
  room is this.start_room

User.methods.activateForSchool = (school) ->
  console.log " activating for school: #{school.name}"
  this.school = school.short
  this.start_room = school.room
  this.state = 'active'

User.pre 'save', (next) -> 
  if not this.activation_code?
    this.activation_code = randomString(12)
  next()

User.pre 'save', (next) ->
  School = mongoose.model 'School'
  SpecialEmail = mongoose.model 'SpecialEmail'
  user = this

  if user.isNew
    [name, domain] = this.email.split '@'

    SpecialEmail.findOne { email: user.email }, (err, special) ->
      if !err && special
        School.findOne { short: special.school }, (err, doc) ->
          return next(err) if err
          user.activateForSchool doc
          next()

      else if eduPattern.test(user.email)
        School.findOne { domain: domain, available: true }, (err, doc) ->
          if doc
            user.activateForSchool doc
            
          next()

      else
        next(new errors.Forbidden())
  else
    next()


mongoose.model 'User', User

Chat = new mongoose.Schema {
  user: { type: mongoose.SchemaTypes.Email, required: true, index: { unique: false, sparse: true } }
  handle:  { type: String, required: true }
  org:  { type: String, required: true, index: { unique: false, sparse: true } }
  type: { type: String, required: true }
  text: { type: String, required: true }
  tags: { type: Array, index: { unique: false } }
  created_at: { type: Date, default: Date.now }
  room: { type: String, required: true }
}

Chat.statics.forOrg = (org, numRecords) -> 
  this.find({}).select('text', 'user', 'created_at', 'handle').where('org', org).desc('created_at').limit(numRecords)

Chat.statics.forRoom = (org, room, numRecords) -> 
  this.forOrg(org, numRecords).where('room', room)

mongoose.model 'Chat', Chat

db = mongoose.connect mongo_uri, (err) ->
  console.log "Trying to connect to mongo"
  if err
    console.log "PROBLEM CONNECTING TO MONGO: " + err

module.exports.User = mongoose.model('User')
module.exports.Chat = mongoose.model('Chat')
module.exports.School = mongoose.model('School')
module.exports.SpecialEmail = mongoose.model('SpecialEmail')

