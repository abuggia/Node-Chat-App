app = require('./app.coffee')

port = (process.env.PORT || 3000)
app.listen(port);

console.log "Listening on #{port}"

# Chat via NowJS
everyone = require("now").initialize app, { "socketio": { "transports": ["xhr-polling"] } }
everyone.now.pub = (msg) ->
  everyone.now.sub this.now.name, msg

everyone.now.eachUser = (fn) ->
  everyone.getUsers (users) ->
    fn(user) for user in users


