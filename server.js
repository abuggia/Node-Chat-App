var express = require('express'),
    app = express.createServer(),
    email = require('./email'),
    models = require('./models'),
    utils = require('./utils')
    User = models.User;
    Errors = models.Errors,
    subdomainPattern = new RegExp("\\w+\." + process.env.ROOT_URL);

app.configure(function(){
  app.use(express.methodOverride());
  app.use(express.bodyParser());
  app.use(express.cookieParser());
  app.use(express.session( { secret: 'H26DFuLKfgde5DFklkRD347BG34' } ));
  app.use(app.router);
  app.use(express.static(__dirname + '/public'));
});

// Redirect subdomains to root for SEO
app.all("*", function(req, res, next){ 
  if(subdomainPattern .test(req.headers.host)) {
    res.writeHead(302, { 'Location': 'http://' + process.env.ROOT_URL });
    res.end();
  } else {
    next(); 
  }
}); 

// Routing
// =======
app.get('/users/:email', function(req, res) {
  User.findOne({ email: req.params.email }, function(err, user) {
    if (!user) {
      res.send(404);
    } else if (err) {
      res.send(500);
    } else {
      res.contentType('json');
      res.send(user);
    }
  });
});

app.get('/user/activate/:activation_code', function(req, res) {
  User.findOne({ activation_code: req.params.activation_code }, function(err, user) {
    if (!user) {
      res.send(404);
    } else if (err) {
      res.send(500);
    } else {
      res.contentType('json');
      res.send(user);
    }
  });
});

app.post('/users', function(req, res) {
  var user = new User();
  user.email = req.body.user.email;
  user.activation_code = utils.randomString(12);

  user.save(function (err) {
    if (err) {
      if (err === Errors.CampusNotReadyYet) {
        res.send(420);

      } else if (err === Errors.NotEduAddress) {
        res.send(403);

      } else {
        res.send(500);
      }
    } else {
      email.send(process.env.MONITORING_EMAIL, "New user signed up: " + user.email, " cool ");
      email.send(user.email, "CampusChat signup 2", "Thank you for signing up with campus chat.  Use the link below to activate you account.\n\nhttp://" + process.env.ROOT_URL + "?activation_code=" + user.activation_code);
      console.log("shoudl have sent both");
      res.send(200);
    }
  });
});

app.post('/user/:email', function(req, res) {
  User.findOne({ email: req.params.email }, function(err, user) {
    if (!user) {
      res.send(404);
    } else if (err) {
      res.send(500);
    } else {
      user.handle = req.body.user.email;
      user.setPassword(req.body.user.password);
      user.save(function(err) {
        res.send((err ? 500 : 200));
      });
    }
  });
});

app.post('/session', function(req, res) {
  User.authenticate(req.body.email, req.body.password, function(err, user) {
    if (err) {
      res.send(401);
    } else {
      req.session.user = user
      res.send(200);
    }
  });
});

app.listen((process.env.PORT || 3000));


// Chat via NowJS
// ==============
var everyone = require("now").initialize(app, {"socketio": {"transports": ["xhr-polling"]}});
everyone.now.pub = function(msg) {
  everyone.now.sub(this.now.name, msg);
}

everyone.now.eachUser = function(fn) {
  everyone.getUsers(function (users) {
    for (var i = 0; i < users.length; i++) fn(users[i]);
  });
};

