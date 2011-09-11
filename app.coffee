express = require("express") 
app = express.createServer() 
subdomainPattern = new RegExp("\w+\." + process.env.ROOT_URL)
UserView = require('./views/user.coffee')
errors = require('./errors.coffee')

app.configure ->
  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session { secret : "H26DFuLKfgde5DFklkRD347BG34" }
  app.use app.router
  app.use express.static(__dirname + "/public")
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })


# Redirect subdomains to root for SEO
app.all "*", (req, res, next) -> 
  if subdomainPattern.test req.headers.host
    res.writeHead 302, { 'Location': 'http://' + process.env.ROOT_URL }
    res.end()
  else
    next()

app.param 'email', UserView.load
app.error (err, req, res, next) -> 
  res.send(if errors.defined err then err.code else 500)
  next()

app.get '/user/:email', UserView.get
app.get '/users/activate/:activation_code', UserView.activate
app.post '/users', UserView.save
app.post '/users/:email', UserView.update
app.post '/vote/:email', UserView.vote
app.post '/session', UserView.login

module.exports = app
