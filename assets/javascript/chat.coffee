class Rooms
  constructor: (first)->
    @ids = {}
    @ids[first] = 1
    @_ids = _(@ids).chain()
    @current = first
    @last = 1

  has: (name) -> @ids[name]? # use _.include 
  add: (name) -> @ids[name] = ++@last
  remove: (name) -> delete @ids[name]
  switch: (name) -> @current = name
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

resizeChat = ->
  height = $("body").height()
  header = 33 #px
  footer = 40 #px
  margin = 16 #px
  $("#chat").height(height-header-footer-margin)
  $("#chat").scrollTop(1000000)
  button = 100 #px
  $("#enter input").width($("#enter").width()-button)


window.initChat = (org, user) ->
  $input = $ '#enter input'
  $users = $ '#users'
  $chat = $ '#chat'
  $tabs = $ '#tabs'
  $roomsList = $ '#rooms-list'
  $bus = $ document
  rooms = new Rooms org
  resizeChat()
  $(window).resize( ->
    resizeChat()
  )
  
  $roomDialogue = -> $$ "#chat #{rooms.currentSelector()}"
  $roomTab = -> $$ "#tabs #{rooms.currentSelector()}"

  addChat = (name, text, time) -> 
    $render('single-chat', {name: name, text: text, time: time}).appendTo $roomDialogue()
    $chat.scrollTop(1000000)

  addChats = (chats) -> 
    chats.reverse()
    addChat(c.user, c.text, formatTime c.created_at) for c in chats

  addRoom = (room) ->
    rooms.add room
    data = {room: room, domClass: rooms.domClass(room)}
    $tab = $render('room-tab', data).hide().insertBefore($$ "#tabs li.new" )
    $tab.slideOut $tab.innerWidth()
    $render('dialogue-window', data).hide().appendTo $$("#chat")

  goToRoom = (room) ->
    $roomDialogue().hide() 
    $roomTab().removeClass("active")
    addRoom(room) if not rooms.has room
    rooms.switch room
    $roomTab().addClass("active")
    $roomDialogue().show()
    $bus.trigger "room-changed"
    
  closeRoom = (room) ->
    goToRoom(rooms.closest room) if $$("#tabs #{rooms.selector room}").hasClass 'active'
    $$("#tabs #{rooms.selector room}").remove()
    $$("#chat #{rooms.selector room}").remove()
    rooms.remove room

  pub = ->
    now.pub org, rooms.current, user.email, $input.val()
    $input.val ""

  $bus.bind 'room-changed', -> 
    now.joinRoom(rooms.current)
    $roomDialogue().empty()
    api.chats org, rooms.current, (chats) -> addChats(chats)
    now.eachUserInRoom rooms.current, (user) ->
    user_view = $render("user-list-item", {user: user})
    $$("#users").append user_view

  # Set handlers
  # ------------
  $input.enter pub
  $('#enter button').click pub
  $chat.dclick 'a.hashtag', -> goToRoom $(this).text()
  $chat.dclick '.name a', -> goToRoom $(this).text()
  $tabs.dclick 'li a.close', -> closeRoom $(this).closest('li').find(".room").text()
  $tabs.dclick 'li a.room', -> goToRoom $(this).text()
  $tabs.find(".new").hover -> 
    $(this).animate(width: "180px")
  , ->
    $(this).animate(width: "47px")
    
  # Joining a new room
  roomListOpen = false
  room_input = $$('#tabs .rooms-list input')
  $$('#tabs .new a').hover ->
    room_input.slideOut(110)
  , -> 
    if not roomListOpen 
      room_input.animate({width: 0}, {queue:false, duration:450 }) 

  $$('#tabs .new a').click (e) ->
    roomListOpen = true
    $this = $(this)
    api.rooms org, (list) ->
      $$('#rooms-list').html(render('rooms-list-items', { list: _.reject(list, (room) -> rooms.has room.name) }))
      $$('#rooms-list').show()
      $$('#rooms-list input').focus()
    e.preventDefault()

  $$('#tabs .new').bind "mouseleave", ->
    $roomsList.hide()
    roomListOpen = false

  $$('#rooms-list').dclick 'li a', ->
    $roomsList.hide()
    goToRoom $(this).find('.roomName').text()

  $$('#rooms-list').delegate 'input', 'keydown', (e) ->
    code = keyCode(e)
    if code is 32
      e.preventDefault();
 
  $$('#rooms-list').delegate 'input', 'keyup', (e) ->
    code = keyCode(e)
    if code is 13
      e.preventDefault();
      $roomsList.hide()
      $$('#tabs .join').hide()
      goToRoom $(this).val()


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

