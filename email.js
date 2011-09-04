  
var mailer = require("mailer");

var setTransmissionInfo = function(options) {
  options.authentication = "login";
  options.host = process.CC_SMTP_HOST;
  options.username = process.CC_SMTP_USERNAME;
  options.password = process.CC_SMTP_PASSWORD;
  options.ssl = true;
  return options;
}

var send = function(to, subject, msg) {
  var options = setTransmissionInfo({});
  options.from = process.CC_EMAIL_FROM;
  options.domain = process.CC_EMAIL_FROM_DOMAIN;
  options.port = "25";

  options.to = to;
  options.subject = subject;
  options.body = msg;

  mailer.send(options);
  console.log("Sent email to " + to);
}
 
exports.send = send