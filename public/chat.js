(function() {
  var Rooms;
  Rooms = (function() {
    function Rooms(room) {
      this.rooms = [room];
      this.current = room;
    }
    Rooms.prototype.hasRoom = function(name) {
      return _.include(this.rooms, name);
    };
    Rooms.prototype.addRoom = function(name) {
      return this.rooms.push(name);
    };
    Rooms.prototype.switchRoom = function(name) {
      return this.current = name;
    };
    Rooms.prototype.domClass = function(room) {
      return "room-" + (_.indexOf(this.rooms, room));
    };
    Rooms.prototype.currentClass = function() {
      return this.domClass(this.current);
    };
    Rooms.prototype.currentSelector = function() {
      return '.' + this.currentClass();
    };
    return Rooms;
  })();
  window.initChat = function(room, user) {
    var $chat, $input, $roomDialogue, $roomTab, $tabs, $users, addChat, addChats, addRoom, closeRoom, eu, goToRoom, org, pub, rooms, tabView;
    $input = $("#enter input");
    $users = $("#users");
    $chat = $("#chat");
    $tabs = $("#tabs");
    eu = window.encodeURIComponent;
    org = room;
    rooms = new Rooms(room);
    window.rooms = rooms;
    $roomDialogue = function() {
      return $chat.find(rooms.currentSelector());
    };
    $roomTab = function() {
      return $tabs.find(rooms.currentSelector());
    };
    addChat = function(name, text, time) {
      var msg;
      msg = "<div><span class=\"time\">" + time + "</span><span class=\"name\"><a href=\"#\">" + name + "</a></span><span class=\"text\">" + text + "</span></div>";
      $roomDialogue().append(msg);
      return $chat.scrollTop(1000000);
    };
    addChats = function(chats) {
      chats.reverse();
      return $.each(chats, function(index, chat) {
        return addChat(chat.user, chat.text, formatTime(new Date(chat.created_at)));
      });
    };
    addRoom = function(room) {
      var diag;
      console.log("add room: ", room);
      rooms.addRoom(room);
      $tabs.append(tabView(room));
      diag = $("<div class=\"dialogue " + (rooms.domClass(room)) + "\"></div>");
      return $chat.find(".dialogue").hide();
    };
    goToRoom = function(room) {
      if (!rooms.hasRoom(room)) {
        addRoom(room);
      }
      console.log($roomDialogue);
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
    closeRoom = function(room) {
      var tab;
      tab = $tabs.find("." + rooms.domClass(room));
      console.log("closing: ", room);
      if (tab.hasClass('active')) {
        goToRoom(rooms.prevRoom(num));
      }
      tab.remove();
      return $chat.find(rooms.domClass(room)).remove();
    };
    tabView = function(room) {
      return "<li class=\"" + (rooms.domClass(room)) + "\" data-room-name=\"" + room + "\">" + room + "<a href=\"#\" class=\"close\">x<li>";
    };
    now.ready(function() {
      now.joinRoom(room);
      $.get("/api/org/" + (eu(org)) + "/chats", function(chats) {
        return addChats(chats);
      });
      return now.eachUserInRoom(room, function(user) {
        return $("<li><a href=\"javascript:void(0)\" class=\"user\" data-user-email=\"" + user.email + "\">" + user.name + "</li>").appendTo($users);
      });
    });
    now.name = user.handle;
    now.email = user.email;
    now.sub = function(name, text) {
      return addChat(name, text, formattedTime());
    };
    pub = function() {
      console.log("pub");
      now.pub(org, user.email, $input.val());
      return $input.val("");
    };
    $input.enter(pub);
    $("#enter button").click(pub);
    $chat.delegate('a.hashtag', 'click', function(e) {
      e.preventDefault();
      return goToRoom(this.innerText);
    });
    $chat.delegate('.side-panel .user a', 'click', function(e) {
      e.preventDefault();
      return goToRoom(this.innerText);
    });
    $tabs.delegate('li a.close', 'click', function(e) {
      return closeRoom($(this).parent().data("room-name"));
    });
    $tabs.delegate('li, li a.close', 'click', function(e) {
      if ($(this).hasClass("close")) {
        return false;
      }
      return goToRoom($(this).data("room-name"));
    });
    $("#users .user").live('click', function(e) {
      var sel_user;
      sel_user = this.innerText;
      if (sel_user !== user.handle) {
        return goToRoom(sel_user);
      }
    });
    return $input.focus();
  };
}).call(this);
