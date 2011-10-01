(function() {
  var Rooms;
  Rooms = (function() {
    function Rooms(first) {
      this.names = {
        first: 1
      };
      this.currentRoomNum = 1;
      this.numRooms = 1;
    }
    Rooms.prototype.hasRoom = function(name) {
      return this.names[name] != null;
    };
    Rooms.prototype.addRoom = function(name) {
      return this.names[name] = ++this.numRooms;
    };
    Rooms.prototype.switchRoom = function(name) {
      return this.currentRoomNum = this.names[name];
    };
    return Rooms;
  })();
  window.initChat = function(room, user) {
    var $chat, $input, $roomDialogue, $roomTab, $tabs, $users, addRoom, goToRoom, pub, rooms;
    $input = $("#enter input");
    $users = $("#users");
    $chat = $("#chat");
    $tabs = $("#tabs");
    rooms = new Rooms(room);
    $roomDialogue = function() {
      return $chat.find(".room-" + rooms.currentRoomNum);
    };
    $roomTab = function() {
      return $tabs.find(".room-" + rooms.currentRoomNum);
    };
    addRoom = function(room) {
      rooms.addRoom(room);
      $tabs.append("<li class=\"room-" + rooms.numRooms + "\">" + room + "<li>");
      return $("<div class=\"room-" + rooms.numRooms + "\"></div>").hide().appendTo($chat);
    };
    goToRoom = function(room) {
      if (!rooms.hasRoom(room)) {
        addRoom(room);
      }
      $roomDialogue().hide();
      $roomTab().removeClass("active");
      rooms.switchRoom(room);
      $roomDialogue().show();
      return $roomTab().addClass("active");
    };
    now.ready(function() {
      now.joinRoom(room);
      return now.eachUserInRoom(room, function(user) {
        return $("<li><a href=\"#\" class=\"user\" data-user-email=\"" + user.email + "\">" + user.name + "</li>").appendTo($users);
      });
    });
    now.name = user.handle;
    now.email = user.email;
    now.sub = function(name, msg) {
      var $c;
      $c = $('<div><span class="time"></span><span class="name"><a href="#">' + name + '</a></span><span class="text">' + msg + '</span></div>');
      $c.appendTo($roomDialogue());
      return $c.find(".time").text(formattedTime());
    };
    pub = function() {
      now.pub(user.email, $input.val());
      return $input.val("");
    };
    $input.enter(pub);
    $("#send").click(pub);
    $chat.delegate("a.hashtag", "click", function(e) {
      e.preventDefault();
      return goToRoom(this.innerText);
    });
    $chat.delegate(".name a", "click", function(e) {
      e.preventDefault();
      return goToRoom(this.innerText);
    });
    return $input.focus();
  };
}).call(this);
