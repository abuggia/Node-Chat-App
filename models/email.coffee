  
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
  console.log "going to send email to #{to}"
  nodemailer.send_mail {sender: from, to: to, subject: subject, body: msg}, (err, success) ->
    if success
      console.log 'Message sent successfully to ' + to
    else
      console.log 'Error sending email: ' + error


#        email.send user.email, "CampusChat signup 2", "Thank you for signing up with campus chat.  Use the link below to activate you account.\n\nhttp://" + process.env.ROOT_URL + "?activation_code=" + user.activation_code
 
module.exports.send = send