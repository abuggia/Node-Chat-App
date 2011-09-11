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
      if not user? then next(new errors.NotFound())
      else
        user.password = undefined
        user.salt = undefined
        req.user = user
        next()

  get: (req, res) -> 
    res.json req.user
    
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

      if user.isEmailExistsError(err)
        res.send new errors.Conflict().code
      if errors.defined err
        res.send err.code
      else if err
        res.send 500
      else
        email.send process.env.MONITORING_EMAIL, "User signed up", "User email: #{user.email}"
        res.send new errors.NotReady

  update: (req, res) ->
    user = req.user
    user.handle = req.body.user.email
    user.setPassword req.body.user.password
    user.save (err) ->
       res.send(err ? 500 : 200)

  vote: (req, res) ->
    user = req.user
    user.vote_open_on_campus = req.body.vote_open_on_campus 
    user.vote_email_me = req.body.vote_email_me
    user.voted = true
    user.save (err) ->
      res.send (err ? 500 : 200)

  login: (req, res) ->
    User.authenticate req.body.email, req.body.password, (err, user) ->
      if err
        res.send 401
      else
        req.session.user = user
        res.send 200
    

module.exports = new UserView

