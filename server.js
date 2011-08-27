
var express = require('express'),
    app = express.createServer();

app.configure(function(){
  app.use(express.static(__dirname + '/public'));
});

var port = process.env.PORT || 3000
app.listen(port)

var everyone = require("now").initialize(app, {"socketio": {"transports": ["xhr-polling"]}});
everyone.now.distributeMessage = function(msg) {
  everyone.now.receiveMessage(this.now.name, msg);
}


