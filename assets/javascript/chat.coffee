class Rooms
  constructor: ->
    @ids = {}
    @_ids = _(@ids).chain()
    @current = undefined
    @last = 0
    @lastChatAuthor = {}
    @lastChatCell = {}
    @users = {}

  has: (name) -> @ids[name]? # use _.include 
  add: (name) -> @ids[name] = ++@last
  remove: (name) -> 
    delete @ids[name]
    @setCell name, undefined
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
  setAuthor: (room, author) -> @lastChatAuthor[room] = author
  isSameAuthor: (room, author) -> 
    last = @lastChatAuthor[room]
    @setAuthor(room, author)
    author is last 
  setCell: (room, $cell) -> @lastChatCell[room] = $cell
  $lastCell: (room) -> @lastChatCell[room]
  usersInCurrent: -> @users[@current] or []
  addUser: (room, user) -> 
    @users[room] = [] unless @users[room]
    @users[room].push(user) unless _.find(@users[room], (u) -> u.email is user.email)
  removeUser: (room, user) -> 
    @users[room] = _.reject(@users[room], (u) -> u.email is user.email)
  
  removeUserFromAll: (user) -> @removeUser(room, user) for room in _.keys(@users)
  addUserToAll: (user) -> @addUser(room, user) for room in _.keys(@users)

  setUsers: (room, users) -> @users[room] = users

window.initChat = (org, user, roomsList, currentRoom) ->
  $chat = $ '#chat'
  $tabs = $ '#tabs'
  $roomsList = $ '#rooms-list'
  rooms = new Rooms()
 
  $roomDialogue = -> $$ "#chat #{rooms.currentSelector()}"
  $roomTab = -> $$ "#tabs #{rooms.currentSelector()}"

  addChat = (room, name, email, text, time, trackMentions, bot) -> 

    if bot
      unless bot.type is 'roomopened' and (bot.room is rooms.current or bot.openedby is user.handle)
        $$("#chat #{rooms.currentSelector()}").append render 'bot-chat-item', {text: text, time: time}
        rooms.setCell room, undefined

    else
      return unless rooms.has room

      mentioned = false
      text = text.replace(new RegExp('\\b(' + user.handle + ')\\b', 'g'), (match) ->
        mentioned = true
        "<span class=\"handle-mention\">#{match}</span>"
      )
 
      if not rooms.isSameAuthor(room, name) or not rooms.$lastCell(rooms.current)
        $c = $render('single-chat', {name: name, text: text, time: time, email: email, yours: (email is user.email)})
        $c.appendTo $$ "#chat #{rooms.selector room}"
        rooms.setCell room, $c.find('td.main')
      else
        rooms.$lastCell(room).append('<p class="text">' + text + '</p>')

      if trackMentions and room isnt rooms.current
        increment $$("#tabs #{rooms.selector room} .num-unread")

        if mentioned
          increment $$("#tabs #{rooms.selector room} .num-mentions")

    $chat.scrollTop(1000000)

  increment = ($e) ->
    v = $e.text()
    v = 0 if /\D/.test(v) or not v
    $e.text(1 + parseInt(v))

  updateUserList = -> 
    users = _.sortBy(rooms.usersInCurrent(), (u) -> u.handle)
    $$('#users').html render "user-list-items", { list: users }
    $$('#user-count-num').text(users.length)

  addChats = (room, chats) -> 
    chats.reverse()
    addChat(room, c.handle, c.user, c.text, formatTime(c.created_at), false, undefined) for c in chats

  addRoom = (room, loadingFromSession = false) ->
    rooms.add room
    data = {room: room, domClass: rooms.domClass(room), org}
    $tab = $render('room-tab', data).hide().insertBefore($$ "#tabs li.new" )
    $tab.slideOut $tab.outerWidth() + 10
    $render('dialogue-window', data).hide().appendTo $$("#chat")
    api.chats org, room, (chats) -> addChats(room, chats)
    api.addRoomToSession room if not loadingFromSession 
    now.withUsersInRoom room, (users) ->
      if users.length is 0
        api.userOpenedRoom org, room, user.email, user.handle

      rooms.setUsers room, users
      now.joinRoom room

  reloadUsers = (room) ->
    now.withUsersInRoom room, (users) ->
      rooms.setUsers room, users
      updateUserList()

  goToRoom = (room) ->
    $roomDialogue().hide() 
    $roomTab().removeClass("active")
    addRoom(room) unless rooms.has room
    rooms.switch room
    $roomTab().addClass("active")
    $roomDialogue().show()
    $$("#tabs #{rooms.selector room} .num-unread").text('')
    $$("#tabs #{rooms.selector room} .num-mentions").text('')
    $$('#enter textarea').focus()
    $$('#chat').scrollTop 1000000
    $$('#users-header').text "People in #{room}"

  closeRoom = (room) ->
    goToRoom(rooms.closest room) if $$("#tabs #{rooms.selector room}").hasClass 'active'
    $$("#tabs #{rooms.selector room}").remove()
    $$("#chat #{rooms.selector room}").remove()
    rooms.remove room
    now.leaveRoom room
    api.removeRoomFromSession room

  pub = ->
    now.pub org, rooms.current, user.email, user.handle, $$("#enter textarea").val()
    $$("#enter textarea").val ''

  modalDialogue = (content) ->
    $$('#modal-dialogue-message').html(content)
    $$('#modal-dialogue').show()
    $$('#modal-dialogue-message').clearError().show()

  hideModalDialogue = () ->
    $$('#modal-dialogue').hide()
    $$('#modal-dialogue-message').hide()
    $$('#enter textarea').focus()

  changeNameDialogue = ->
    $d = modalDialogue(render('change-name-form'))
    $input = $d.find('input').focus()
    $d.find('button.change').click -> changeName($input)
    $input.enter -> changeName($input)
    $input.keyup = (e) -> preventSpaces(e)

  changeName = ($input) ->
    newName = $input.val().replace /\s/, ''
    if newName.length < 1
      $$('#modal-dialogue-message').addError 'New name cannot be blank'
    else
      api.changeHandle user.email, newName, (->
        now.name = newName
        hideModalDialogue()
        user.handle = newName
        #brute force
        rooms.removeUserFromAll(user)
        rooms.addUserToAll(user)
        updateUserList()
      ), (->
        $$('#modal-dialogue-message').addError 'Sorry.  This username has been taken.'
      )

  preventSpaces = (e) ->
    code = keyCode(e)
    if !codeIsLetter(code) and !codeIsNumber(code) and code != 8
      e.preventDefault();

  updateRoomLists = ->
    api.topRooms org, 5, (rooms) -> $$('#top-rooms').html render 'top-rooms-items', { rooms: rooms }
    api.roomsByNewest org, (rooms) -> $$('#all-rooms').html render 'all-rooms-items', { rooms: rooms }


  [headerHeight, footerHeight, margin, sidePanelOffset] = [33, 56, 22, 290] #px
  resizeChat = ->
    height = $$("body").height() - headerHeight - footerHeight - margin
    $$("#chat").height(height).scrollTop 1000000
    $$("#side-panel .flex-container").height Math.round (height - sidePanelOffset) / 2

  # Set handlers
  # ------------
  $$('#enter textarea').enter pub
  $('#enter button').clickWithoutDefault pub
  $chat.dclick 'a.hashtag', ($this) -> goToRoom $this.text()
  #$chat.dclick '.name a', ($this) -> goToRoom $this.text()
  $tabs.dclick 'li a.close', ($this) -> closeRoom $this.closest('li').find(".room .name").text()
  $tabs.dclick 'li a.room', ($this) -> goToRoom $this.find('.name').text()
  $$('#side-panel').dclick 'li.room-choice a', ($this) -> goToRoom $this.find('.roomName').text()
  $('a#logout').clickWithoutDefault -> api.logout()
  $(window).resize resizeChat
  $$('#top-right a.avatar').clickWithoutDefault ($this) -> $$('#top-right .options').toggle()
  $$('#modal-dialogue-message').dclick 'button.cancel', hideModalDialogue
  $$('#users').dclick 'li a', ->
  $('a#change-name').clickWithoutDefault -> 
    changeNameDialogue()
    $$('#top-right .options').toggle()

  # Joining a new room
  # ------------------
  $tabs.find(".new").hover -> 
    $(this).animate(width: "180px")
  , ->
    $(this).animate(width: "47px")
 
  roomListOpen = false
  $$('#tabs .new a').hover ->
    $$('#tabs .rooms-list input').slideOut(80)
  , -> 
    if not roomListOpen 
      $$('#tabs .rooms-list input').animate({width: 0}, {queue:false, duration:450 }) 

  $$('#tabs .new a').clickWithoutDefault ($this) ->
    roomListOpen = true
    api.topRooms org, 10, (list) ->
      $$('#rooms-list').html(render('rooms-list-items', { list: _.reject(list, (room) -> rooms.has room.name) }))
      $$('#rooms-list').show()
      $$('#rooms-list input').focus()

  $$('#tabs .new').bind "mouseleave", ->
    $roomsList.hide()
    roomListOpen = false

  $$('#rooms-list').dclick 'li a', ($this) ->
    $roomsList.hide()
    goToRoom $this.find('.roomName').text()

  $$('#rooms-list').delegate 'input', 'keydown', (e) -> preventSpaces e

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
  now.sub = (room, name, email, text, bot) ->
    addChat(room, name, email, text, formattedTime(), true, bot)

  now.addUser = (room, user) ->
    rooms.addUser(room, user)
    updateUserList() if room is rooms.current
      
  now.removeUser = (room, user) ->
    rooms.removeUser(room, user)
    updateUserList() if room is rooms.current

  now.newRoomOpened = -> updateRoomLists()
  now.reloadUsers = reloadUsers
      
  init = false
  now.ready -> 
    if not init
      addRoom(r, true) for r in roomsList
      goToRoom currentRoom
      resizeChat()
      updateRoomLists()
      init = true
 
  $$("#enter textarea").focus()

