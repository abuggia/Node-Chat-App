
var express = require('express'),
    app = express.createServer(),
    email = require('./email'),
    models = require('./models'),
    User = models.User;

app.configure(function(){
  app.use(express.methodOverride());
  app.use(express.bodyParser());
  app.use(app.router);
  app.use(express.static(__dirname + '/public'));
});

app.listen((process.env.PORT || 3000))

// Routing
// =======
app.get('/users/:email', function(req, res) {
  User.findOne({ email: req.params.email }, function(err, result) {
    if (!result) {
      res.send(404);
    } else if (err) {
      res.send(500);
    } else {
      res.contentType('json');
      res.send({ "handle" : result.handle });
     }
  });
});

app.post('/users', function(req, res) {
  var user = new User();
  user.email = req.body.user.email;

  user.save( function (err) {
    if (err) {
      res.send(500);
    } else {
      email.send(process.env.MONITORING_EMAIL, "New user signed up" + user.email, " cool ");
      res.send(200);
    }
  });
});


// Chat via NowJS
// ==============
var everyone = require("now").initialize(app, {"socketio": {"transports": ["xhr-polling"]}});
everyone.now.pub = function(msg) {
  everyone.now.sub(this.now.name, msg);
}

function keepSending() {
  everyone.now.pub("Hey this is awesome");
  setTimeout(keepSending, 200)
}




