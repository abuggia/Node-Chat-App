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
  $bus = $ document
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
    $("<li class=\"#{rooms.domClass room}\"><a href=\"#\" class=\"room\">#{room}</a><a href=\"#\" class=\"close\">x</a></li>").hide().insertBefore($tabs.find('li.new')).show("fast")
    $("<div class=\"dialogue #{rooms.domClass room}\"></div>").hide().appendTo($chat)

  goToRoom = (room) ->
    isNew = not rooms.hasRoom(room)

    $roomDialogue().hide() 
    $roomTab().removeClass("active")

    addRoom(room) if isNew 
    rooms.switchRoom room
    $roomTab().addClass("active")
    $roomDialogue().show()

    $bus.trigger "room-changed"

    if isNew
      $.get "/api/org/#{eu(org)}/room/#{eu(room)}/chats", (chats) -> addChats(chats)
    
  closeRoom = (room) ->
    $tab = $tabs.find(rooms.selector room);
    $dialogue = $chat.find(rooms.selector room);

    if $tab.hasClass 'active'
      goToRoom(rooms.closest(room))

    $tab.remove()
    $dialogue.remove()

  pub = ->
    now.pub org, rooms.current, user.email, $input.val()
    $input.val ""
 
  $bus.bind "room-changed", -> 
    now.joinRoom(rooms.current)
    $.get "/api/org/#{eu(org)}/room/#{eu(rooms.current)}/chats", (chats) -> addChats(chats)
    now.eachUserInRoom rooms.current, (user) -> $("<li><a href=\"#\" class=\"user\" data-user-email=\"#{user.email}\">#{user.name}</li>").appendTo $users.empty()

  # Set handlers
  # ------------
  $input.enter pub
  $("#send").click pub

  $chat.dclick 'a.hashtag', (e) -> goToRoom this.innerText
  $chat.dclick '.name a', -> goToRoom this.innerText
  $tabs.dclick 'li a.close', -> closeRoom $(this).closest('li').find(".room").text()
  $tabs.dclick 'click', -> goToRoom $(this).text()
  $tabs.find(".new a").hover -> $(this).find(".join").show "fast"

  hideJoinNewRoom = -> $newRoom.find(".join").hide("fast")

  roomListOpen = false
  $newRoom.hover (e) ->
    $newRoom.find(".join").show("fast")
  , (e) ->
    hideJoinNewRoom() if not roomListOpen
      
  $tabs.find(".new a").click (e) ->
    e.preventDefault()
    roomListOpen = true
    position = $(this).position()
    $.get "/api/org/#{org}/rooms", (rooms) ->
      $roomsList
        .empty()
        .append( _.reduce(rooms, ( (m, room) -> "#{m}<li><a href=\"#\">#{room}</a></li>" ), "") )
        .css( {top: (position.top + 30) + 'px', left: (position.left - 4) + 'px' } )
        .show()

  $roomsList.bind "mouseleave", (e) ->
    $roomsList.hide()
    hideJoinNewRoom()
    roomListOpen = false

  $roomsList.dclick 'click', (e) ->
    $roomsList.hide()
    $newRoom.find(".join").hide()
    goToRoom $(this).text()

  # Set up now
  # ----------
  now.ready -> $bus.trigger "room-changed"
  now.name = user.handle
  now.email = user.email
  now.sub = (name, text) -> addChat(name, text, formattedTime())

  $input.focus()

