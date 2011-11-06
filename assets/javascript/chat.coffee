class Rooms
  constructor: ->
    @ids = {}
    @_ids = _(@ids).chain()
    @current = undefined
    @last = 0

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

window.initChat = (org, user, roomsList, currentRoom) ->
  $chat = $ '#chat'
  $tabs = $ '#tabs'
  $roomsList = $ '#rooms-list'
  rooms = new Rooms()
 
  $roomDialogue = -> $$ "#chat #{rooms.currentSelector()}"
  $roomTab = -> $$ "#tabs #{rooms.currentSelector()}"

  addChat = (name, email, text, time) -> 
    $render('single-chat', {name: name, text: text, time: time, email: email, linkName: (email isnt user.email)}).appendTo $roomDialogue()
    $chat.scrollTop(1000000)

  addChats = (chats) -> 
    chats.reverse()
    addChat(c.handle, c.user, c.text, formatTime c.created_at) for c in chats

  addRoom = (room, loadingFromSession = false) ->
    rooms.add room
    data = {room: room, domClass: rooms.domClass(room)}
    $tab = $render('room-tab', data).hide().insertBefore($$ "#tabs li.new" )
    $tab.slideOut $tab.innerWidth()
    $render('dialogue-window', data).hide().appendTo $$("#chat")
    if not loadingFromSession 
      api.addRoomToSession room

  goToRoom = (room) ->
    $roomDialogue().hide() 
    $roomTab().removeClass("active")
    addRoom(room) if not rooms.has room
    rooms.switch room
    $roomTab().addClass("active")
    $roomDialogue().show()
    now.joinRoom(rooms.current)
    $roomDialogue().empty()
    api.chats org, rooms.current, (chats) -> addChats(chats)
    now.withUsersInRoom rooms.current, (users) ->
      $$("#users").html render("user-list-items", { list: users })

  closeRoom = (room) ->
    goToRoom(rooms.closest room) if $$("#tabs #{rooms.selector room}").hasClass 'active'
    $$("#tabs #{rooms.selector room}").remove()
    $$("#chat #{rooms.selector room}").remove()
    rooms.remove room
    now.leaveRoom room
    api.removeRoomFromSession room

  pub = ->
    now.pub org, rooms.current, user.email, user.handle, $$("#enter input").val()
    $$("#enter input").val ''

  [headerHeight, footerHeight, margin] = [33, 40, 16] #px
  resizeChat = ->
    $("#chat").height($$("body").height() - headerHeight - footerHeight - margin).scrollTop(1000000)
    $$("#enter input").width($$("#enter").width() - 100)

  # Set handlers
  # ------------
  $$('#enter input').enter pub
  $('#enter button').clickWithoutDefault pub
  $chat.dclick 'a.hashtag', ($this) -> goToRoom $this.text()
  $chat.dclick '.name a', ($this) -> goToRoom $this.text()
  $tabs.dclick 'li a.close', ($this) -> closeRoom $this.closest('li').find(".room").text()
  $tabs.dclick 'li a.room', ($this) -> goToRoom $this.text()
  $('a#logout').clickWithoutDefault -> api.logout()
  $$('#users').dclick '.user', ($this) -> goToRoom $this.text() if $this.text() != user.handle
  $(window).resize resizeChat
  $$('#top-right a.avatar').clickWithoutDefault ($this) ->
    $$('#top-right .options').show()

  # Joining a new room
  # ------------------
  $tabs.find(".new").hover -> 
    $(this).animate(width: "180px")
  , ->
    $(this).animate(width: "47px")
 
  roomListOpen = false
  $$('#tabs .new a').hover ->
    $$('#tabs .rooms-list input').slideOut(110)
  , -> 
    if not roomListOpen 
      $$('#tabs .rooms-list input').animate({width: 0}, {queue:false, duration:450 }) 

  $$('#tabs .new a').clickWithoutDefault ($this) ->
    roomListOpen = true
    api.rooms org, (list) ->
      $$('#rooms-list').html(render('rooms-list-items', { list: _.reject(list, (room) -> rooms.has room.name) }))
      $$('#rooms-list').show()
      $$('#rooms-list input').focus()

  $$('#tabs .new').bind "mouseleave", ->
    $roomsList.hide()
    roomListOpen = false

  $$('#rooms-list').dclick 'li a', ($this) ->
    $roomsList.hide()
    goToRoom $this.find('.roomName').text()

  $$('#rooms-list').delegate 'input', 'keydown', (e) ->
    code = keyCode(e)
    if !codeIsLetter(code) and !codeIsNumber(code) and code != 8
      e.preventDefault();
 
  $$('#rooms-list').delegate 'input', 'keyup', (e) ->
    code = keyCode(e)
    if code is 13
      e.preventDefault();
      $roomsList.hide()
      goToRoom '#' + $(this).val()

  # Set up now
  # ----------
  now.name = user.handle
  now.email = user.email
  now.sub = (room, name, email, text) -> addChat(name, email, text, formattedTime()) if room is rooms.current
  init = false
  now.ready -> 
    if not init
      addRoom(r, true) for r in roomsList
      goToRoom currentRoom
      resizeChat()
      init = true
 
  $$("#enter input").focus()

