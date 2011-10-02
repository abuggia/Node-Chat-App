nowjs = require("now")
Chat = require('../models/models.coffee').Chat
NUM_CHATS = 20

class ChatView
  constructor: (app) ->
    that = this
    @everyone = nowjs.initialize app, { "socketio": { "transports": ["xhr-polling"] } }

    @everyone.now.pub = (org, email, msg) -> that.everyone.now.sub this.now.name, that.processMessage(org, email, msg)
    @everyone.now.joinRoom = (room) -> nowjs.getGroup(room).addUser(this.user.clientId)
    @everyone.now.eachUserInRoom = (room, fn) ->
      nowjs.getGroup(room).getUsers (clientIds) -> 
        nowjs.getClient(clientId, -> fn { name: this.now.name, email: this.now.email }) for clientId in clientIds

  processMessage: (org, email, msg) ->
    tags = []
    ret = msg.replace(/#\w+/gi, (match) ->
      tags.push match
      "<a href=\"#\" class=\"hashtag\">#{match}</a>".toLowerCase()
    )
    ret = ret.replace(/http\:\/\/[^\s"']+/gi, "<a href=\"$&\" class=\"hash\">$&</a>")

    new Chat({ user: email, text: ret, tags: tags, org: org }).save (err) -> console.error "Error saving chat: #{err}\n#{err.stack}" if err
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
    console.log "getting chats for org: #{req.params.org}"
    Chat.forOrg(req.params.org, NUM_CHATS).run (err, doc) -> res.json doc

  getChatsForRoom: (req, res) ->
    console.log "getting chats for room: #{req.params.room}"
    Chat.forOrg(req.params.org, NUM_CHATS).where('tags').in([req.params.room]).run (err, doc) -> res.json doc


module.exports = (app) -> new ChatView(app)
