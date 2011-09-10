express = require("express") 
app = express.createServer() 
subdomainPattern = new RegExp("\w+\." + process.env.ROOT_URL)
UserView = require('./views/user.coffee')

app.configure ->
  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session({ secret : "H26DFuLKfgde5DFklkRD347BG34" })
  app.use app.router
  app.use express.static(__dirname + "/public")

# Redirect subdomains to root for SEO
app.all "*", (req, res, next) -> 
  if subdomainPattern.test req.headers.host
    res.writeHead 302, { 'Location': 'http://' + process.env.ROOT_URL }
    res.end()
  else
    next()

app.get '/users/:email', UserView.get
app.get '/user/activate/:activation_code', UserView.activate
app.post '/users', UserView.save
app.post '/user/:email', UserView.update
app.post '/session', UserView.login

app.listen((process.env.PORT || 3000));

# Chat via NowJS
everyone = require("now").initialize app, { "socketio": { "transports": ["xhr-polling"] } }
everyone.now.pub = (msg) ->
  everyone.now.sub this.now.name, msg

everyone.now.eachUser = (fn) ->
  everyone.getUsers (users) ->
    fn(user) for user in users


