window.initChat = (room, user) ->
  $input = $ "#enter input"
  $send = $ "#send"
  $d = $ "#chat .dialogue"
  $users = $ "#users"

  now.name = user.handle
  now.sub = (name, msg) ->
    $chat = $ '<div><span class="time"></span><span class="name">' + name + '</span><span class="text">' + msg + '</span></div>'
    $chat.appendTo $d
    $chat.find(".time").text formattedTime

  pub = ->
    now.pub $input.val()
    $input.val ""
 
  refreshUsers = ->
    $list = $ '<ul></ul>'
    now.eachUser (user) ->
      $list.append "<li>" + user + "</li>"

    $user.find("ul").replaceWith $list
    setTimeout refreshUsers, 5000

  $input.enter pub
  $send.click pub
  $input.focus()

  now.ready ->
    now.joinRoom(room)
    now.eachUserInRoom room, (user) ->
      $('<li>' + user.name + '</li>').appendTo($users)


