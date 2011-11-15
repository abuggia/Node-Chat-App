nowjs = require("now")
_ = require("underscore")
Chat = require('../models/models.coffee').Chat
NUM_CHATS = 25

class ChatView
  constructor: (app) ->
    that = this
    leaveRoom = (user, group) -> 
      group.removeUser user.clientId
      nowjs.getClient user.clientId, -> group.now.removeUser group.groupName, userFromNowContext(this.now)

    leaveRooms = (user) -> 
      if user
        user.getGroups (groups) -> leaveRoom(user, group) for group in groups

    withLoadedUsers = (clientIds, acc, callback) ->
      if clientIds.length > 0
        nowjs.getClient clientIds.pop(), -> 
          acc.push userFromNowContext(this.now)
          withLoadedUsers clientIds, acc, callback
      else
        callback(acc)

    userFromNowContext = (now) -> { name: now.name, email: now.email, handle: now.name }

    @everyone = nowjs.initialize app, { "socketio": { "transports": ["xhr-polling"] } }

    @everyone.now.pub = (org, room, email, handle, msg) -> that.everyone.now.sub room, handle, email, that.processMessage(org, room, email, handle, msg)
    @everyone.now.leaveRoom = (room) -> leaveRoom this.user, nowjs.getGroup(room)

    @everyone.now.joinRoom = (room) ->
      group = nowjs.getGroup(room)
      clientId = this.user.clientId
      group.hasClient clientId, (seriously) -> group.addUser(clientId) unless seriously
      group.now.addUser room, userFromNowContext(this.now)

    nowjs.on 'disconnect', -> 
      nowjs.getClient this.user.clientId, (user) ->
        leaveRooms(user) if user

    @everyone.now.withUsersInRoom = (room, fn) ->
      nowjs.getGroup(room).getUsers (clientIds) -> 
        withLoadedUsers clientIds, [], (users) ->
          fn(users)

  processMessage: (org, room, email, handle, msg) ->
    tags = []
    ret = msg.replace(/&/g, '&amp;')
             .replace(/</g, '&lt;')
             .replace(/>/g, '&gt;')
    ret = ret.replace(/#\w+/gi, (match) ->
      tags.push match
      "<a href=\"#\" class=\"hashtag\">#{match}</a>".toLowerCase()
    )
    ret = ret.replace(/http[s]?\:\/\/[^\s"']+/gi, "<a href=\"$&\" target=\"_blank\" class=\"hash\">$&</a>")

    new Chat({ user: email, handle: handle, text: ret, tags: tags, room: room, org: org, type: 'School' }).save (err) -> console.error "Error saving chat: #{err}\n#{err.stack}" if err
    ret

  loadRoom: (req, res) ->
    user = req.session.user
    room = req.params[0]

    if room isnt user?.start_room
      res.redirect '/'
    else
      console.log " sending rooms #{JSON.stringify(req.session.rooms)}"

      req.session.rooms or= [room]
      req.session.currentRoom or= room

      res.render "../public/chat.html", { org: user.school, room: req.session.currentRoom, rooms: req.session.rooms, user: {handle: user.handle, email: user.email} } 

  getChats: (req, res) ->
    Chat.forRoom(req.params.org, req.params.room, NUM_CHATS).run (err, doc) -> res.json doc

  getRooms: (req, res) ->
    loadRoomCounts = (rooms, data, callback) ->
      if rooms.length > 0
        room = rooms.pop()
        nowjs.getGroup(room).count (count) ->
          data.push { name: room, numUsers: count }
          loadRoomCounts(rooms, data, callback)
      else
        callback _.sortBy(data, (d) -> -1 * d.numUsers)

    Chat.distinct 'room', {org: req.params.org}, (err, rooms) ->
      return next(err) if err
      loadRoomCounts rooms, [], (data) -> res.json data


module.exports = (app) -> new ChatView(app)

