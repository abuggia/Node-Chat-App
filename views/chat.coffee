nowjs = require("now")
Chat = require('../models/models.coffee').Chat
NUM_CHATS = 25

class ChatView
  constructor: (app) ->
    that = this
    @everyone = nowjs.initialize app, { "socketio": { "transports": ["xhr-polling"] } }

    @everyone.now.pub = (org, room, email, msg) -> that.everyone.now.sub this.now.name, that.processMessage(org, room, email, msg)
    @everyone.now.joinRoom = (room) -> nowjs.getGroup(room).addUser(this.user.clientId)
    @everyone.now.eachUserInRoom = (room, fn) ->
      nowjs.getGroup(room).getUsers (clientIds) -> 
        nowjs.getClient(clientId, -> fn { name: this.now.name, email: this.now.email }) for clientId in clientIds

  processMessage: (org, room, email, msg) ->
    tags = []
    ret = msg.replace(/#\w+/gi, (match) ->
      tags.push match
      "<a href=\"#\" class=\"hashtag\">#{match}</a>".toLowerCase()
    )
    ret = ret.replace(/http\:\/\/[^\s"']+/gi, "<a href=\"$&\" class=\"hash\">$&</a>")

    new Chat({ user: email, text: ret, tags: tags, room: room, org: org, type: 'School' }).save (err) -> console.error "Error saving chat: #{err}\n#{err.stack}" if err
    ret
 
  loadRoom: (req, res) ->
    room = req.params[0]
    user = req.session.user

    if not user or room is not user.start_room
      res.send 403
    else
      req.session.current_room = room
      res.render "../public/chat.html", { room: room, user: { handle: user.handle, email: user.email }, layout: false } 

  getChats: (req, res) ->
    console.log " org is #{req.params.org} and room is #{req.params.room}"
    Chat.forRoom(req.params.org, req.params.room, NUM_CHATS).run (err, doc) -> res.json doc


module.exports = (app) -> new ChatView(app)
