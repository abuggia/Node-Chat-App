  

var email = require("mailer");

var send = function(address, subject, msg) {
  var options = {};
  options.to = address;
  options.from = 'campuschat';
  options.subject = subject;
  options.body = msg;

  /*
  email.send {
      host : "localhost",              // smtp server hostname
      ssl: true,                        // for SSL support - REQUIRES NODE v0.3.x OR HIGHER
      domain : "localhost",            // domain used by client to identify itself to server
      */
  
  console.log("Sending email to " + email);
}
 
exports.send = send