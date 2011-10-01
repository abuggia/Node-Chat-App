class Rooms
  constructor: (first)->
    @names = { first: 1 }
    @currentRoomNum = 1
    @numRooms = 1

  hasRoom: (name) -> @names[name]?
  addRoom: (name) -> @names[name] = ++@numRooms
  switchRoom: (name) -> @currentRoomNum = @names[name]

window.initChat = (room, user) ->
  $input = $ "#enter input"
  $users = $ "#users"
  $chat = $ "#chat"
  $tabs = $ "#tabs"
  rooms = new Rooms room

  $roomDialogue = -> $chat.find(".room-#{rooms.currentRoomNum}")
  $roomTab = -> $tabs.find(".room-#{rooms.currentRoomNum}")

  addRoom = (room) ->
    rooms.addRoom room
    $tabs.append "<li class=\"room-#{rooms.numRooms}\">#{room}<li>"
    $("<div class=\"room-#{rooms.numRooms}\"></div>").hide().appendTo($chat)

  goToRoom = (room) ->
    addRoom(room) if not rooms.hasRoom(room)

    $roomDialogue().hide() 
    $roomTab().removeClass("active")
    rooms.switchRoom room
    $roomDialogue().show()
    $roomTab().addClass("active")

  # Set up now
  # ----------
  now.ready ->
    now.joinRoom(room)
    now.eachUserInRoom room, (user) ->
      $("<li><a href=\"#\" class=\"user\" data-user-email=\"#{user.email}\">#{user.name}</li>").appendTo($users)

  now.name = user.handle
  now.email = user.email
  now.sub = (name, msg) ->
    $c = $('<div><span class="time"></span><span class="name"><a href="#">' + name + '</a></span><span class="text">' + msg + '</span></div>')
    $c.appendTo $roomDialogue()
    $c.find(".time").text formattedTime()


  # Set handlers
  # ------------
  pub = ->
    now.pub user.email, $input.val()
    $input.val ""
 
  $input.enter pub
  $("#send").click pub

  $chat.delegate "a.hashtag", "click", (e) ->
    e.preventDefault()
    goToRoom this.innerText

  $chat.delegate ".name a", "click", (e) ->
    e.preventDefault()
    goToRoom this.innerText

  $input.focus()
