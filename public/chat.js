(function() {
  $(function() {
    var $d, $input, $send, $users, pub, refreshUsers;
    $input = $("#enter input");
    $send = $("#send");
    $d = $("#chat .dialogue");
    $users = $("#users");
    now.name = 'adam';
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
    $input.enter(pub);
    $send.click(pub);
    $input.focus();
    return refreshUsers = function() {
      var $list;
      $list = $('<ul></ul>');
      now.eachUser(function(user) {
        return $list.append("<li>" + user + "</li>");
      });
      $user.find("ul").replaceWith($list);
      return setTimeout(refreshUsers, 5000);
    };
  });
}).call(this);
