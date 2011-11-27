nowjs = require("now")
_ = require("underscore")
Chat = require('../models/models.coffee').Chat
UserEnteredEmptyRoomEvent = require('../models/models.coffee').UserEnteredEmptyRoomEvent
NUM_CHATS = 150

filteredAccumulatorGenerator = (filter) ->
  acc = []
  ret = ->
    if arguments.length is 0
      acc
    else
      acc.push arguments[0] if not filter arguments[0]
      ret

roomsWithCountsAcc = -> filteredAccumulatorGenerator (data) -> data.numUsers is 0

_.mixin {
  indexBy: (col, prop) ->
    ret = {}
    ret[item[prop]] = item for item in col
    ret

  sortReverse: (arr, fn) ->
    _.sortBy(arr, fn).reverse()
}

withRoomCounts = (org, acc, callback) -> 
  Chat.distinct 'room', { org: org }, (err, rooms) ->
    return callback(err) if err
    withRoomCountsRecur rooms, acc, callback

withRoomCountsRecur = (rooms, acc, callback) -> 
  if rooms.length > 0
    room = rooms.pop()
    nowjs.getGroup(room).count (count) -> withRoomCountsRecur(rooms, acc({ name: room, numUsers: count }), callback)
  else
    callback acc()

roomsWithCounts = (org, fn) -> withRoomCounts org, roomsWithCountsAcc(), fn

everyone = undefined

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


    everyone = nowjs.initialize app, { "socketio": { "transports": ["xhr-polling"] } }

    userFromNowContext = (now) -> { name: now.name, email: now.email, handle: now.name }

    everyone.now.pub = (org, room, email, handle, msg) -> everyone.now.sub room, handle, email, that.processMessage(org, room, email, handle, msg)
    everyone.now.leaveRoom = (room) -> leaveRoom this.user, nowjs.getGroup(room)

    everyone.now.joinRoom = (room) ->
      group = nowjs.getGroup(room)
      clientId = this.user.clientId
      group.hasClient clientId, (seriously) -> group.addUser(clientId) unless seriously
      group.now.addUser room, userFromNowContext(this.now)

    nowjs.on 'disconnect', -> 
      nowjs.getClient this.user.clientId, (user) ->
        leaveRooms(user) if user

    everyone.now.withUsersInRoom = (room, fn) ->
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
      req.session.rooms or= [room]
      req.session.currentRoom or= room

      res.render "../public/chat.html", { org: user.school, room: req.session.currentRoom, rooms: req.session.rooms, user: {handle: user.handle, email: user.email} } 

  getChats: (req, res) ->
    Chat.forRoom(req.params.org, req.params.room, NUM_CHATS).run (err, doc) -> res.json doc

  getTopRooms: (req, res) ->
    roomsWithCounts req.params.org, (rooms) ->
      rooms = _.sortReverse rooms, (room) -> room.numUsers
      num = _.min [rooms.length, req.params.num]
      res.json rooms[0..(num-1)]

  getRoomsByNewest: (req, res) ->
    roomsWithCounts req.params.org, (rooms) ->
      UserEnteredEmptyRoomEvent.forOrg(req.params.org).run (err, events) ->
        if err
          console.error err
          console.error err.stack
          res.send 500
        else
          events = _.indexBy events, 'room'
          room.openedAt = events[room.name].occured_at for room in rooms

          longTimeAgo = new Date 1977, 5, 17
          res.json _.sortReverse rooms, (room) -> room.openedAt or longTimeAgo

  userOpenedRoom: (req, res) ->
    UserEnteredEmptyRoomEvent.addOrUpdate req.params.org, req.body.room, req.body.user, (err, event) ->
      if err
        console.error err
        console.error err.stack
        res.send 500
      else
        everyone.now.sub 'current', 'bot', 'bot@campusch.at', "#{req.body.handle} has just opened room <a href=\"#\" class=\"hashtag\">#{req.body.room}</a>", { type:'roomopened', room: req.body.room }


module.exports = (app) -> new ChatView(app)



