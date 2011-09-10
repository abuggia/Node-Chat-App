  
nodemailer = require('nodemailer');

nodemailer.SMTP = {
  host: process.env.CC_SMTP_HOST,
  port: 587,
  use_authentication: true,
  user: process.env.CC_SMTP_USERNAME,
  pass: process.env.CC_SMTP_PASSWORD
}

from = process.env.CC_EMAIL_FROM

send = (to, subject, msg) ->
  nodemailer.send_mail {sender: from, to: to, subject: subject, body: msg}, (err, success) ->
    if success
      console.log 'Message sent successfully to ' + to
    else
      console.log 'Error sending email: ' + error
 
exports.send = send