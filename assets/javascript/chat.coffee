class Rooms
  constructor: (first)->
    @ids = { first: 1 }
    @_names = _(@names).chain 
    @current = first
    @last = 1

  hasRoom: (name) -> @ids[name]?
  addRoom: (name) -> @ids[name] = ++@last
  switchRoom: (name) -> @current = name
  currentClass: -> this.domClass(@current)
  currentSelector: -> '.' + this.currentClass()
  domClass: (room): -> "room-#{@ids[@currentRoom]}" 

  #prevRoomName: (num) -> this.roomName(this.prevRoomNum(num))
  #prevRoomNum: (num) -> @_name.values.reject( (n) -> n >= num ).max.value
  #roomName: (num) -> @_name.key.find((name) -> @name[name] is n).value
 
 

window.initChat = (room, user) ->
  $input = $ "#enter input"
  $users = $ "#users"
  $chat = $ "#chat"
  $tabs = $ "#tabs"
  eu = window.encodeURIComponent
  org = room
  rooms = new Rooms room

  $roomDialogue = -> $chat.find rooms.currentSelector
  $roomTab = -> $tabs.find rooms.currentSelector

  addChat = (name, text, time) ->
    $("<div><span class=\"time\">#{time}</span><span class=\"name\"><a href=\"#\">#{name}</a></span><span class=\"text\">#{text}</span></div>").appendTo($roomDialogue())

  addChats = (chats) ->
    $.each chats, (index, chat) -> 
      addChat(chat.user, chat.text, formatTime(new Date(chat.created_at)))

  addRoom = (room) ->
    rooms.addRoom room
    $tabs.append "<li class=\"#{room.domClass room}\" data-room-num=\"#{room}\">#{room}<a href=\"#\" class=\"close\">x<li>"
    $("<div class=\"dialogue room-#{room.domClass room}\"></div>").hide().appendTo($chat)

  goToRoom = (room) ->
    addRoom(room) if not rooms.hasRoom(room)

    $roomDialogue().hide() 
    $roomTab().removeClass("active")
    rooms.switchRoom room
    $roomTab().addClass("active")
    $roomDialogue().show()
    console.log "/api/org/#{eu(org)}/room/#{eu(room)}/chats" 
    $.get "/api/org/#{eu(org)}/room/#{eu(room)}/chats", (chats) -> addChats(chats)

  closeRoom = (room) ->
    $tab = $tabs.find("room-#{num}");
    if $tab.hasClass 'active'
      goToRoom(rooms.prevRoom(num))

    $tab.remove()
    $chat.find(".room-#{num}").remove()


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

  $chat.delegate 'a.hashtag', 'click', (e) ->
    e.preventDefault()
    goToRoom this.innerText

  $chat.delegate '.name a', 'click', (e) ->
    e.preventDefault()
    goToRoom this.innerText

  $tabs.delegate 'li a.close', 'click', (e) ->
    e.preventDefault()
    closeRoom $(this).data("room")



  $input.focus()


