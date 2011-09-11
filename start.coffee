app = require('./app.coffee')

app.listen((process.env.PORT || 3000));

# Chat via NowJS
everyone = require("now").initialize app, { "socketio": { "transports": ["xhr-polling"] } }
everyone.now.pub = (msg) ->
  everyone.now.sub this.now.name, msg

everyone.now.eachUser = (fn) ->
  everyone.getUsers (users) ->
    fn(user) for user in users


