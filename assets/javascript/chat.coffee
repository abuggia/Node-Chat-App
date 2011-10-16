class Rooms
  constructor: (first)->
    @ids = {}
    @ids[first] = 1
    @_ids = _(@ids).chain()
    @current = first
    @last = 1

  hasRoom: (name) -> @ids[name]?
  addRoom: (name) -> @ids[name] = ++@last
  switchRoom: (name) -> @current = name
  currentClass: -> this.domClass(@current)
  currentSelector: -> this.selector(@current) 
  selector: (room) -> '.' + this.domClass(room)
  domClass: (room) -> "room-#{ @ids[room] }" 
  roomFromNum: (num) -> 
    ids = @ids
    @_ids.keys().find((name) -> 
      ids[name] is num
    ).value()
  maxPrev: (num) -> @_ids.values().reject( (n) -> n >= num ).max().value()
  minNext: (num) -> @_ids.values().reject( (n) -> n <= num ).min().value()
  closest: (room) -> 
    num = @ids[room]
    newNum = this.maxPrev(num) or this.minNext(num)
    this.roomFromNum(newNum)


window.initChat = (room, user) ->
  $input = $ '#enter input'
  $users = $ '#users'
  $chat = $ '#chat'
  $tabs = $ '#tabs'
  $roomsList = $ '#rooms-list'
  $newRoom = $tabs.find('.new a')
  eu = window.encodeURIComponent
  org = room
  rooms = new Rooms room

  $roomDialogue = -> $chat.find rooms.currentSelector()
  $roomTab = -> $tabs.find rooms.currentSelector()

  addChat = (name, text, time) ->
    $("<div><span class=\"time\">#{time}</span><span class=\"name\"><a href=\"#\">#{name}</a></span><span class=\"text\">#{text}</span></div>").appendTo($roomDialogue())

  addChats = (chats) ->
    $.each chats, (index, chat) -> 
      addChat(chat.user, chat.text, formatTime(new Date(chat.created_at)))

  addRoom = (room) ->
    rooms.addRoom room
    $tabs.append "<li class=\"#{rooms.domClass room}\"><a href=\"#\" class=\"room\">#{room}</a><a href=\"#\" class=\"close\">x<li>"
    $("<div class=\"dialogue #{rooms.domClass room}\"></div>").hide().appendTo($chat)

  goToRoom = (room) ->
    isNew = not rooms.hasRoom(room)

    $roomDialogue().hide() 
    $roomTab().removeClass("active")

    addRoom(room) if isNew 
    rooms.switchRoom room
    $roomTab().addClass("active")
    $roomDialogue().show()

    if isNew
      $.get "/api/org/#{eu(org)}/room/#{eu(room)}/chats", (chats) -> addChats(chats)
    
  closeRoom = (room) ->
    $tab = $tabs.find(rooms.selector room);
    $dialogue = $chat.find(rooms.selector room);

    if $tab.hasClass 'active'
      goToRoom(rooms.closest(room))

    $tab.remove()
    $dialogue.remove()


  # Set up now
  # ----------
  now.ready ->
    now.joinRoom(room)
    $.get "/api/org/#{eu(org)}/room/#{rooms.current}/chats", (chats) -> addChats(chats)
    now.eachUserInRoom room, (user) -> $("<li><a href=\"#\" class=\"user\" data-user-email=\"#{user.email}\">#{user.name}</li>").appendTo($users)

  now.name = user.handle
  now.email = user.email
  now.sub = (name, text) -> addChat(name, text, formattedTime())

  # Set handlers
  # ------------
  pub = ->
    now.pub org, rooms.current, user.email, $input.val()
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
    closeRoom $(this).closest('li').find(".room").text()

  $tabs.delegate 'li a.room', 'click', (e) ->
    e.preventDefault()
    goToRoom $(this).text()

  $tabs.find(".new a").hover (e) ->
    e.preventDefault()
    $(this).find(".join").show "fast"


  roomListOpen = false
  $newRoom.hover (e) ->
    $newRoom.find(".join").show("fast");
  , (e) ->
    if not roomListOpen
      $newRoom.find(".join").hide("fast");

      
  $tabs.find(".new a").click (e) ->
    roomListOpen = true
    e.preventDefault()
    position = $(this).position()
    $.get "/api/org/#{org}/rooms", (rooms) ->
      $roomsList
        .empty()
        .append( _.reduce(rooms, ( (m, room) -> "#{m}<li><a href=\"#\">#{room}</a></li>" ), "") )
        .css( {top: (position.top + 30) + 'px', left: (position.left - 4) + 'px' } )
        .show()

  $roomsList.bind "mouseleave", (e) ->
    roomListOpen = true
    $roomsList.hide()
    $newRoom.find(".join").hide("fast");

  $input.focus()

