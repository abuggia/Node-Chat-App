#bcrypt = require('bcrypt')
models = require('../models/models.coffee')
User = models.User
Errors = models.Errors 
errors = require('./../errors.coffee')
crypto = require('crypto');

class UserView

  constructor: () ->

  load: (req, res, next, email) ->
    User.findOne { email: email }, (err, user) ->
      if err? then next(err)
      if not user then next(errors.NotFound)
      else
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

      if errors.defined err
        res.send err.code
      else if err
        res.send 500
      else
        email.send process.env.MONITORING_EMAIL, "New user signed up: " + user.email, " cool "
        email.send user.email, "CampusChat signup 2", "Thank you for signing up with campus chat.  Use the link below to activate you account.\n\nhttp://" + process.env.ROOT_URL + "?activation_code=" + user.activation_code
        res.send 200

  update: (req, res) ->
    user = req.user
    user.handle = req.body.user.email
    user.setPassword req.body.user.password
    user.save (err) ->
       res.send(err ? 500 : 200)

  vote: (req, res) ->
    user = req.user
    user.vote_open_on_campus = req.body.user.vote_open_on_campus 
    user.vote_email_me = req.body.user.vote_email_me
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

