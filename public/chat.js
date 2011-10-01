(function() {
  var Rooms;
  Rooms = (function() {
    function Rooms(first) {
      this.names = {
        first: 1
      };
      this.currentRoomNum = 1;
      this.roomIndex = 1;
    }
    Rooms.prototype.currentRoomClass = function() {
      return "room-" + this.currentRoomNum;
    };
    Rooms.prototype.hasRoom = function(name) {
      return this.names[name] != null;
    };
    Rooms.prototype.addRoom = function(name) {
      return this.names[name] = this.roomIndex++;
    };
    return Rooms;
  })();
  window.initChat = function(room, user) {
    var $chat, $d, $input, $send, $tabs, $users, addRoom, encodeId, goToRoom, pub, rooms;
    $input = $("#enter input");
    $send = $("#send");
    $d = $("#chat .dialogue");
    $users = $("#users");
    $chat = $("#chat");
    $tabs = $("#tabs");
    rooms = new Rooms(room);
    $("#chat ." + (rooms.currentRoomClass())).show();
    now.name = user.handle;
    now.email = user.email;
    now.sub = function(name, msg) {
      $chat = $('<div><span class="time"></span><span class="name"><a href="#">' + name + '</a></span><span class="text">' + msg + '</span></div>');
      $d = $("#chat ." + (rooms.currentRoomClass()));
      $chat.appendTo($d);
      console.log("appended to " + $d);
      return $chat.find(".time").text(formattedTime);
    };
    pub = function() {
      now.pub($input.val());
      return $input.val("");
    };
    $input.enter(pub);
    $send.click(pub);
    $input.focus();
    now.ready(function() {
      now.joinRoom(room);
      return now.eachUserInRoom(room, function(user) {
        return $("<li><a href=\"#\" class=\"user\" data-user-email=\"" + user.email + "\">" + user.name + "</li>").appendTo($users);
      });
    });
    encodeId = function(id) {
      id = '' + id;
      id = id.replace('#', '__hash__');
      return id = id.replace('@', '__at__');
    };
    addRoom = function(room) {
      var $dialogue, num;
      num = _.keys(rooms).length;
      $tabs.append("<li class=\"room-" + num + "\">" + room + "<li>");
      $dialogue = $("<div class=\"room-" + num + "\"></div>").hide().appendTo($chat);
      return rooms[room] = num;
    };
    goToRoom = function(room) {
      alert(" going to room: " + room);
      if (!rooms[room]) {
        return addRoom(room);
      }
    };
    $chat.delegate("a.hashtag", "click", function(e) {
      e.preventDefault();
      return goToRoom(this.innerText);
    });
    return $chat.delegate(".name a", "click", function(e) {
      e.preventDefault();
      return goToRoom(this.innerText);
    });
  };
}).call(this);
