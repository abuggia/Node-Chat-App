class Rooms
  constructor: (first)->
    @ids = {}
    @ids[first] = 1
    @_ids = _(@ids).chain()
    @current = first
    @last = 1

  hasRoom: (name) -> @ids[name]? # use _.include 
  addRoom: (name) -> @ids[name] = ++@last
  switchRoom: (name) -> @current = name
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
  $bus = $ document
  org = room
  rooms = new Rooms room
  window.rooms = rooms

  $roomDialogue = -> $chat.find rooms.currentSelector()
  $roomTab = -> $tabs.find rooms.currentSelector()

  addChat = (name, text, time) -> $render('single-chat', {name: name, text: text, time: time}).appendTo $roomDialogue()
#    $chat.scrollTop(1000000)

  addChats = (chats) -> addChat(c.user, c.text, formatTime c.created_at) for c in chats

  addRoom = (room) ->
    rooms.addRoom room
    data = {room: room, domClass: rooms.domClass(room)}
    $render('room-tab', data).insertBefore $$("#tabs li.new")
    $render('dialogue-window', data).hide().appendTo $$("#chat")

  goToRoom = (room) ->
    isNew = not rooms.hasRoom(room)

    $roomDialogue().hide() 
    $roomTab().removeClass("active")

    addRoom(room) if isNew 
    rooms.switchRoom room
    $roomTab().addClass("active")
    $roomDialogue().show()

    $bus.trigger "room-changed"
    api.chats(org, room, (chats) -> addChats(chats)) if isNew
    
  closeRoom = (room) ->
    $tab = $tabs.find(rooms.selector room);
    $dialogue = $chat.find(rooms.selector room);

    goToRoom(rooms.closest(room)) if $tab.hasClass 'active'

    $tab.remove()
    $dialogue.remove()

  pub = ->
    now.pub org, rooms.current, user.email, $input.val()
    $input.val ""
 
  $bus.bind 'room-changed', -> 
    now.joinRoom(rooms.current)
    api.chats org, rooms.current, (chats) -> addChats(chats)
    now.eachUserInRoom rooms.current, (user) -> $render("user-list-item", {user: user}).appendTo $$("#users").empty()

  # Set handlers
  # ------------
  $input.enter pub
  $('#enter button').click pub
  $chat.dclick 'a.hashtag', -> goToRoom $(this).text()
  $chat.dclick '.name a', -> goToRoom $(this).text()
  $tabs.dclick 'li a.close', -> closeRoom $(this).closest('li').find(".room").text()
  $tabs.dclick 'click', -> goToRoom $(this).text()
  $tabs.find(".new a").hover -> $(this).find(".join").show "fast"

  roomListOpen = false
  $$('#tabs .new a').hover (-> $$('#tabs .join').show('fast')), (-> $$('#tabs .join').hide('fast') if not roomListOpen)
      
  $tabs.find(".new a").click (e) ->
    e.preventDefault()
    roomListOpen = true
    position = $(this).position()
    api.rooms org, (rooms) ->
      $render('rooms-list', {rooms: rooms}).replaceAll $$('#rooms-list')
      $$('#rooms-list').moveDownLeftOf(30, -4, this).slideDown('fast')

  $$('#rooms-list').bind "mouseleave", ->
    $roomsList.hide()
    $$('#tabs .join').hide('fast')
    roomListOpen = false

  $$('#rooms-list').dclick 'li a', ->
    $roomsList.hide()
    $$('#tabs .join').hide('fast')
    goToRoom $(this).text()

  # Set up now
  # ----------
  now.ready -> $bus.trigger "room-changed"
  now.name = user.handle
  now.email = user.email
  now.sub = (name, text) -> addChat(name, text, formattedTime())

  $$('#users').dclick '.user', ->
    handle = $(this).text()
    goToRoom handle if handle != user.handle
  
  $input.focus()

