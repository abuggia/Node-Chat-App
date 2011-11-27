express = require("express") 
app = express.createServer() 
UserView = require('./views/user.coffee')
ChatView = require('./views/chat.coffee')(app)
errors = require('./errors.coffee')
subdomainPattern = new RegExp("\w+\." + process.env.ROOT_URL)

Db = require('mongodb').Db
Server = require('mongodb').Server

server_config = new Server(process.env.MONGO_SERVER, process.env.MONGO_PORT, {auto_reconnect: true, native_parser: true})
db = new Db('db', server_config, {})
if process.env.MONGO_USER
  console.log "Authenticating ..."
  db.authenticate process.env.MONGO_USER, process.env.MONGO_PASSWORD, ->
    console.log "Authenticated"
mongoStore = require('connect-mongodb');

app.configure ->
  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use express.cookieParser()
  #app.use express.session { secret : "H26DFuLKfgde5DFklkRD347BG34" }
  app.use express.session { secret : "H26DFuLKfgde5DFklkRD347BG34", store: new mongoStore({db: db}) }
  app.use app.router
  app.use express.static(__dirname + "/public")
  app.set("view engine", "html");
  app.set("view options", { layout: false });
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
app.post '/api/handle/:email/change_handle', UserView.changeHandle
app.post '/api/user/:email/checkschool', UserView.checkSchool
app.post '/api/vote/:email', UserView.vote
app.get '/api/votes/:email', UserView.voteCount
app.post '/api/session', UserView.login
app.delete '/api/session', UserView.logout
app.post '/api/session/room', UserView.addRoomToSession
app.delete '/api/session/room', UserView.removeRoomFromSession
app.get /^\/([A-Z]\w+$)/, ChatView.loadRoom
app.get '/api/org/:org/room/:room/chats', ChatView.getChats
app.get '/api/org/:org/rooms', ChatView.getRooms
app.get '/api/org/:org/toprooms/:num', ChatView.getTopRooms
app.get '/api/org/:org/roomsbynewest', ChatView.getRoomsByNewest
app.post '/api/org/:org/useropenedroom', ChatView.userOpenedRoom

app.get '/', UserView.welcome
app.get '/terms', (req, res) -> res.render "../public/terms.html"
app.get '/privacy', (req, res) -> res.render "../public/privacy.html"

module.exports = app



