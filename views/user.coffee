_ = require("underscore")
models = require('../models/models.coffee')
email = require('../models/email.coffee')
errors = require('./../errors.coffee')
crypto = require('crypto');
log = console.log
User = models.User

class UserView
  constructor: () ->

  load: (req, res, next, email) ->
    User.findOne { email: email }, (err, user) ->
      if err? then next(err)
      else if not user? then next(new errors.NotFound())
      else
        user.password = undefined
        user.salt = undefined
        req.user = user
        next()

  get: (req, res) -> 
    res.json req.user.safe_json()
    
  activate: (req, res) ->
    User.findOne { activation_code: req.params.activation_code }, (err, user) ->
      if !user
        res.send 404
      else
        user.password = undefined
        res.json(user);

  save: (req, res) -> 
    user = new User();
    user.email = req.body.user.email

    user.save (err) ->
      if err
        if errors.defined err
          res.send err.code
 
        else if user.isEmailExistsError(err)
          res.send new errors.Conflict().code
        else
          console.log "User save for #{user.email} and error is #{JSON.stringify(err)}"
          res.send 500
          res.json user.safe_json()

      else
        email.send process.env.MONITORING_EMAIL, "User signed up", "User email: #{user.email}"
        if !user.school
          res.send (new errors.NotReady()).code
        else
          res.json user.safe_json()

  update: (req, res) ->
    user = req.user
    user.handle = req.body.user.handle
    user.setPassword req.body.user.password

    user.save (err) ->
      res.send(err ? 500 : 200)

  changeHandle: (req, res) ->
    User.update req.user.email, { handle: req.body.handle }, (err) -> 
      res.send(err ? 500 : 200)

  vote: (req, res) ->
    user = req.user
    user.vote_open_on_campus = req.body.vote_open_on_campus 
    user.vote_email_me = req.body.vote_email_me
    user.voted = true
    user.save (err) ->
      res.send (err ? 500 : 200)

  voteCount: (req, res) ->
    User.count { school: req.user.school, vote_open_on_campus: true }, (err, count) ->
      if err?
        res 500
      else
        User.findByEmail req.user.email, (err, user) ->
          if user
            res.json { school: user.schoolOrBest(), count: count }
          else
            res.json { school: 'your school', count: 0 }

  checkSchool: (req, res) ->
    School.findOne { domain: req.user.domain(), available: true }, (err, doc) -> 
      if doc
        user.activateForSchool doc
        user.save (err) ->
          res.send 500 if err
          res.json user.safe_json
      else
        res.send 404

  welcome: (req, res) ->
    if req.session?.user?.start_room
      res.redirect "/#{req.session.user.start_room}"
    else
      res.render "../public/index.html"
      
  login: (req, res) ->
    User.authenticate req.body.email, req.body.password, (err, user) ->
      if err
        console.log "err is #{err}"
        console.log err.stack
        res.send 401
      else
        req.session.user = user
        res.json user.safe_json()

  logout: (req, res) ->
    req.session.destroy()
    res.send 200

  addRoomToSession: (req, res) ->
    room = req.body.room
    req.session.rooms = _.union((req.session.rooms || []), [room]) 

    log "room is #{room} and rooms is now #{JSON.stringify(req.session.rooms)}"

    res.send 200

  removeRoomFromSession: (req, res) ->
    req.session.rooms = _.without((req.session.rooms || []), req.body.room)
    res.send 200


module.exports = new UserView

