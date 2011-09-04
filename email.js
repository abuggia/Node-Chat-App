  
var nodemailer = require('nodemailer');

nodemailer.SMTP = {
  host: process.env.CC_SMTP_HOST,
  port: 587,
  use_authentication: true,
  user: process.env.CC_SMTP_USERNAME,
  pass: process.env.CC_SMTP_PASSWORD
}

var send = function(to, subject, msg) {
  var options = {};
  options.sender = process.env.CC_EMAIL_FROM;
  options.to = to;
  options.subject = subject;
  options.body = msg;

  nodemailer.send_mail(options,  function(error, success){
    if (success) {
      console.log('Message sent successfully to ' + to);
    } else {
      console.log('Error sending email: ' + error);
    }
  });
}
 
exports.send = send