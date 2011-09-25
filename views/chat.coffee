

class ChatView
  constructor: ->

  loadRoom: (req, res) ->
    room = req.params[0]
    user = req.session.user

    if room is not user.start_room
      res.send 403
    else
      req.session.current_room = room
      res.render "../public/chat.html", { room: room, layout: false } 


module.exports = new ChatView
