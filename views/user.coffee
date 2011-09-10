#bcrypt = require('bcrypt')
models = require('../models/models.coffee')
User = models.User
Errors = models.Errors 
crypto = require('crypto');

chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz";


class UserView

  constructor: () ->

  get: (req, res) -> 
    User.findOne { email: req.params.email }, (err, user) ->
      res.contentType 'json'
      res.send if !user then 404 else if err then 500 else user

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
      switch err
        when Errors.CampusNotReadyYet then res.send 420
        when Errors.NotEduAddresst then res.send 403
        when undefined
          email.send process.env.MONITORING_EMAIL, "New user signed up: " + user.email, " cool "
          email.send user.email, "CampusChat signup 2", "Thank you for signing up with campus chat.  Use the link below to activate you account.\n\nhttp://" + process.env.ROOT_URL + "?activation_code=" + user.activation_code
          console.log "shoudl have sent both"
          res.send 200
        else res.send 500

  update: (req, res) ->
    User.findOne { email: req.params.email }, (err, user) ->
      if  !user
        res.send 404
      else if err
        res.send 500
      else
        user.handle = req.body.user.email
        user.setPassword req.body.user.password
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

