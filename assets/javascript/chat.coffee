class Rooms
  constructor: (first)->
    @names = { first: 1 }
    @currentRoomNum = 1
    @roomIndex = 1

  currentRoomClass: ->
    "room-#{@currentRoomNum}"

  hasRoom: (name) ->
    @names[name]?

  addRoom: (name) ->
    @names[name] = @roomIndex++


window.initChat = (room, user) ->
  $input = $ "#enter input"
  $send = $ "#send"
  $d = $ "#chat .dialogue"
  $users = $ "#users"
  $chat = $ "#chat"
  $tabs = $ "#tabs"
  rooms = new Rooms room
  $("#chat .#{rooms.currentRoomClass()}").show()


  now.name = user.handle
  now.email = user.email
  now.sub = (name, msg) ->
    $chat = $ '<div><span class="time"></span><span class="name"><a href="#">' + name + '</a></span><span class="text">' + msg + '</span></div>'

    $d = $("#chat .#{rooms.currentRoomClass()}")
    
    $chat.appendTo $d
    console.log "appended to " + $d
    $chat.find(".time").text formattedTime

  pub = ->
    now.pub $input.val()
    $input.val ""
 
  $input.enter pub
  $send.click pub
  $input.focus()

  now.ready ->
    now.joinRoom(room)
    now.eachUserInRoom room, (user) ->
      $("<li><a href=\"#\" class=\"user\" data-user-email=\"#{user.email}\">#{user.name}</li>").appendTo($users)

  encodeId = (id) ->
    id = '' + id
    id = id.replace('#', '__hash__') 
    id = id.replace('@', '__at__') 

  addRoom = (room) ->
    num = _.keys(rooms).length
    $tabs.append "<li class=\"room-#{num}\">#{room}<li>"
    $dialogue = $("<div class=\"room-#{num}\"></div>").hide().appendTo($chat)
    rooms[room] = num

  goToRoom = (room) ->
    alert(" going to room: " + room)
    if not rooms[room]
      addRoom room


  $chat.delegate "a.hashtag", "click", (e) ->
    e.preventDefault()
    goToRoom this.innerText

  $chat.delegate ".name a", "click", (e) ->
    e.preventDefault()
    goToRoom this.innerText


