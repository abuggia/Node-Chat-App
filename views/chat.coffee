

class ChatView
  constructor: (@app) ->

  loadRoom: (req, res) ->
    room = req.params[0]
    user = req.session.user

    if not user.canAccessRoom
      res.send 403
    else
      req.session.currentRoom = room
      @app.render "public/chat.html", { room: room } 


module.exports = (app) -> new ChatView(app)
