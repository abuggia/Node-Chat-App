nowjs = require("now")
_ = require("underscore")
Chat = require('../models/models.coffee').Chat
NUM_CHATS = 25

class ChatView
  constructor: (app) ->
    that = this
    @everyone = nowjs.initialize app, { "socketio": { "transports": ["xhr-polling"] } }

    @everyone.now.pub = (org, room, email, handle, msg) -> that.everyone.now.sub room, handle, email, that.processMessage(org, room, email, handle, msg)
    @everyone.now.joinRoom = (room) -> nowjs.getGroup(room).addUser(this.user.clientId)
    @everyone.now.leaveRoom = (room) -> nowjs.getGroup(room).removeUser(this.user.clientId)

    withLoadedUsers = (clientIds, acc, callback) ->
      if clientIds.length > 0
        nowjs.getClient clientIds.pop(), -> 
          acc.push { name: this.now.name, email: this.now.email, handle: this.now.name}
          withLoadedUsers clientIds, acc, callback
      else
        callback(acc)

    @everyone.now.withUsersInRoom = (room, fn) ->
      nowjs.getGroup(room).getUsers (clientIds) -> 
        withLoadedUsers clientIds, [], (users) ->
          fn(users)

  processMessage: (org, room, email, handle, msg) ->
    tags = []
    ret = msg.replace(/#\w+/gi, (match) ->
      tags.push match
      "<a href=\"#\" class=\"hashtag\">#{match}</a>".toLowerCase()
    )
    ret = ret.replace(/http[s]?\:\/\/[^\s"']+/gi, "<a href=\"$&\" target=\"_blank\" class=\"hash\">$&</a>")

    new Chat({ user: email, handle: handle, text: ret, tags: tags, room: room, org: org, type: 'School' }).save (err) -> console.error "Error saving chat: #{err}\n#{err.stack}" if err
    ret

  loadRoom: (req, res) ->
    room = req.params[0]
    user = req.session.user
    currentRoom = req.session.currentRoom || room
    rooms = req.session.rooms || [currentRoom]

    if not user or room is not user.start_room
      res.redirect '/'
    else
      req.session.current_room = room

      console.log " here and rooms is #{rooms}"

      # TODO: fucking stupid. Figure out why jptl is displaying crap json
      roomsJson = ["'#{room}'" for room in rooms].join(',')
      console.log " here and rooms is #{rooms} and roomsJson is #{roomsJson}"

      res.render "../public/chat.html", { org: user.school, room: currentRoom, rooms: roomsJson, user: { handle: user.handle, email: user.email }, layout: false } 

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

