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
    var $chat, $input, $roomDialogue, $roomTab, $tabs, $users, addChat, addChats, addRoom, eu, goToRoom, org, pub, rooms;
    $input = $("#enter input");
    $users = $("#users");
    $chat = $("#chat");
    $tabs = $("#tabs");
    eu = window.encodeURIComponent;
    org = room;
    rooms = new Rooms(room);
    $roomDialogue = function() {
      return $chat.find(".room-" + rooms.currentRoomNum);
    };
    $roomTab = function() {
      return $tabs.find(".room-" + rooms.currentRoomNum);
    };
    addChat = function(name, text, time) {
      return $("<div><span class=\"time\">" + time + "</span><span class=\"name\"><a href=\"#\">" + name + "</a></span><span class=\"text\">" + text + "</span></div>").appendTo($roomDialogue());
    };
    addChats = function(chats) {
      return $.each(chats, function(index, chat) {
        return addChat(chat.user, chat.text, formatTime(new Date(chat.created_at)));
      });
    };
    addRoom = function(room) {
      rooms.addRoom(room);
      $tabs.append("<li class=\"room-" + rooms.numRooms + "\">" + room + "<a href=\"#\">x<li>");
      return $("<div class=\"room-" + rooms.numRooms + "\"></div>").hide().appendTo($chat);
    };
    goToRoom = function(room) {
      if (!rooms.hasRoom(room)) {
        addRoom(room);
      }
      $roomDialogue().hide();
      $roomTab().removeClass("active");
      rooms.switchRoom(room);
      $roomTab().addClass("active");
      $roomDialogue().show();
      console.log("/api/org/" + (eu(org)) + "/room/" + (eu(room)) + "/chats");
      return $.get("/api/org/" + (eu(org)) + "/room/" + (eu(room)) + "/chats", function(chats) {
        return addChats(chats);
      });
    };
    now.ready(function() {
      now.joinRoom(room);
      $.get("/api/org/" + (eu(org)) + "/chats", function(chats) {
        return addChats(chats);
      });
      return now.eachUserInRoom(room, function(user) {
        return $("<li><a href=\"#\" class=\"user\" data-user-email=\"" + user.email + "\">" + user.name + "</li>").appendTo($users);
      });
    });
    now.name = user.handle;
    now.email = user.email;
    now.sub = function(name, text) {
      return addChat(name, text, formattedTime());
    };
    pub = function() {
      now.pub(org, user.email, $input.val());
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
