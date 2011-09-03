
var express = require('express'),
    app = express.createServer();

var mongoose = require('mongoose');
var mongo_uri = process.env.MONGOLAB_URI || 'mongodb://localhost/db'

mongoose.model('User', new mongoose.Schema({
  email: String,
  handle: String,
  password: String
}));

var db = mongoose.connect(mongo_uri);

var User = mongoose.model('User');

app.configure(function(){
  app.use(express.methodOverride());
  app.use(express.bodyParser());
  app.use(app.router);
  app.use(express.static(__dirname + '/public'));
});

var port = process.env.PORT || 3000
app.listen(port)

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
      res.send(200);
    }
  });
});


/* Now JS */

var everyone = require("now").initialize(app, {"socketio": {"transports": ["xhr-polling"]}});
everyone.now.pub = function(msg) {
  everyone.now.sub(this.now.name, msg);
}

function keepSending() {
  everyone.now.pub("Dude", "Hey this is awesome");
  setTimeout(keepSending, 200)
}




