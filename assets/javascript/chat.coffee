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
  eu = window.encodeURIComponent
  org = room
  rooms = new Rooms room

  $roomDialogue = -> $chat.find(".room-#{rooms.currentRoomNum}")
  $roomTab = -> $tabs.find(".room-#{rooms.currentRoomNum}")

  addChat = (name, text, time) ->
    $("<div><span class=\"time\">#{time}</span><span class=\"name\"><a href=\"#\">#{name}</a></span><span class=\"text\">#{text}</span></div>").appendTo($roomDialogue())

  addChats = (chats) ->
    $.each chats, (index, chat) -> 
      addChat(chat.user, chat.text, formatTime(new Date(chat.created_at)))

  addRoom = (room) ->
    rooms.addRoom room
    $tabs.append "<li class=\"room-#{rooms.numRooms}\">#{room}<a href=\"#\">x<li>"
    $("<div class=\"room-#{rooms.numRooms}\"></div>").hide().appendTo($chat)

  goToRoom = (room) ->
    addRoom(room) if not rooms.hasRoom(room)

    $roomDialogue().hide() 
    $roomTab().removeClass("active")
    rooms.switchRoom room
    $roomTab().addClass("active")
    $roomDialogue().show()
    console.log "/api/org/#{eu(org)}/room/#{eu(room)}/chats" 
    $.get "/api/org/#{eu(org)}/room/#{eu(room)}/chats", (chats) -> addChats(chats)

  # Set up now
  # ----------
  now.ready ->
    now.joinRoom(room)
    $.get "/api/org/#{eu(org)}/chats", (chats) -> addChats(chats)
    now.eachUserInRoom room, (user) -> $("<li><a href=\"#\" class=\"user\" data-user-email=\"#{user.email}\">#{user.name}</li>").appendTo($users)

  now.name = user.handle
  now.email = user.email
  now.sub = (name, text) -> addChat(name, text, formattedTime())

  # Set handlers
  # ------------
  pub = ->
    now.pub org, user.email, $input.val()
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
