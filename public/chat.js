(function() {
  window.initChat = function(room, user) {
    var $d, $input, $send, $users, pub, refreshUsers;
    $input = $("#enter input");
    $send = $("#send");
    $d = $("#chat .dialogue");
    $users = $("#users");
    now.name = user.handle;
    now.sub = function(name, msg) {
      var $chat;
      $chat = $('<div><span class="time"></span><span class="name">' + name + '</span><span class="text">' + msg + '</span></div>');
      $chat.appendTo($d);
      return $chat.find(".time").text(formattedTime);
    };
    pub = function() {
      now.pub($input.val());
      return $input.val("");
    };
    refreshUsers = function() {
      var $list;
      $list = $('<ul></ul>');
      now.eachUser(function(user) {
        return $list.append("<li>" + user + "</li>");
      });
      $user.find("ul").replaceWith($list);
      return setTimeout(refreshUsers, 5000);
    };
    $input.enter(pub);
    $send.click(pub);
    $input.focus();
    return now.ready(function() {
      now.joinRoom(room);
      return now.eachUserInRoom(room, function(user) {
        return $('<li>' + user.name + '</li>').appendTo($users);
      });
    });
  };
}).call(this);
