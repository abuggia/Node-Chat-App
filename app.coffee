express = require("express") 
app = express.createServer() 
subdomainPattern = new RegExp("\w+\." + process.env.ROOT_URL)
UserView = require('./views/user.coffee')
ChatView = require('./views/chat.coffee')
errors = require('./errors.coffee')

app.configure ->
  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session { secret : "H26DFuLKfgde5DFklkRD347BG34" }
  app.use app.router
  app.use express.static(__dirname + "/public")
  app.set("view engine", "html");
  app.register(".html", require("jqtpl").express);

app.error (err, req, res, next) -> 
  if errors.defined err 
    res.send err.code
  else
    console.error "CC ERROR: #{err}"
    console.error err.stack
    res.send 500

# Redirect subdomains to root for SEO
app.all "*", (req, res, next) -> 
  if subdomainPattern.test req.headers.host
    res.writeHead 302, { 'Location': 'http://' + process.env.ROOT_URL }
    res.end()
  else
    next()

app.param 'email', UserView.load
app.get '/api/user/:email', UserView.get
app.get '/api/users/activate/:activation_code', UserView.activate
app.post '/api/users', UserView.save
app.post '/api/users/:email', UserView.update
app.post '/api/vote/:email', UserView.vote
app.get '/api/votes/:email', UserView.voteCount
app.post '/api/session', UserView.login
app.get /^\/([A-Z]\w+$)/, ChatView.loadRoom


# Chat via NowJS
nowjs = require("now")
everyone = nowjs.initialize app, { "socketio": { "transports": ["xhr-polling"] } }
everyone.now.pub = (msg) ->
  console.log ">(chat): #{msg}"
  everyone.now.sub this.now.name, msg

everyone.now.eachUserInRoom = (room, fn) ->
  nowjs.getGroup(room).getUsers (clientIds) -> 
    for clientId in clientIds
      console.log " getting client for clientId #{clientId}"
      nowjs.getClient clientId, () -> fn({name: this.now.name})

everyone.now.joinRoom = (room) ->
  nowjs.getGroup(room).addUser(this.user.clientId)



module.exports = app
