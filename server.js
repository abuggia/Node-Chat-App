
var express = require('express'),
    app = express.createServer();

app.configure(function(){
  app.use(express.static(__dirname + '/public'));
  app.set("transports", ["xhr-polling"]); 
  app.set("polling duration", 10); 
});

var port = process.env.PORT || 3000
app.listen(port)

var everyone = require("now").initialize(app);
everyone.now.distributeMessage = function(msg) {
  everyone.now.receiveMessage(this.now.name, msg);
}


