

class ChatView
  constructor: ->

  loadRoom: (req, res) ->
    room = req.params[0]
    user = req.session.user

    if not user or room is not user.start_room
      res.send 403
    else
      req.session.current_room = room
      res.render "../public/chat.html", { room: room, user: { handle: user.handle, email: user.email }, layout: false } 


module.exports = new ChatView
