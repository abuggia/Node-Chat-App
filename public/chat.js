(function() {
  var Rooms;
  Rooms = (function() {
    function Rooms(first) {
      this.ids = {};
      this.ids[first] = 1;
      this._ids = _(this.ids).chain();
      this.current = first;
      this.last = 1;
    }
    Rooms.prototype.hasRoom = function(name) {
      return this.ids[name] != null;
    };
    Rooms.prototype.addRoom = function(name) {
      return this.ids[name] = ++this.last;
    };
    Rooms.prototype.switchRoom = function(name) {
      return this.current = name;
    };
    Rooms.prototype.currentClass = function() {
      return this.domClass(this.current);
    };
    Rooms.prototype.currentSelector = function() {
      return this.selector(this.current);
    };
    Rooms.prototype.selector = function(room) {
      return '.' + this.domClass(room);
    };
    Rooms.prototype.domClass = function(room) {
      return "room-" + this.ids[room];
    };
    Rooms.prototype.roomFromNum = function(num) {
      var ids;
      ids = this.ids;
      return this._ids.keys().find(function(name) {
        return ids[name] === num;
      }).value();
    };
    Rooms.prototype.maxPrev = function(num) {
      return this._ids.values().reject(function(n) {
        return n >= num;
      }).max().value();
    };
    Rooms.prototype.minNext = function(num) {
      return this._ids.values().reject(function(n) {
        return n <= num;
      }).min().value();
    };
    Rooms.prototype.closest = function(room) {
      var newNum, num;
      num = this.ids[room];
      newNum = this.maxPrev(num) || this.minNext(num);
      return this.roomFromNum(newNum);
    };
    return Rooms;
  })();
  window.initChat = function(room, user) {
    var $chat, $input, $newRoom, $roomDialogue, $roomTab, $roomsList, $tabs, $users, addChat, addChats, addRoom, closeRoom, eu, goToRoom, org, pub, roomListOpen, rooms;
    $input = $('#enter input');
    $users = $('#users');
    $chat = $('#chat');
    $tabs = $('#tabs');
    $roomsList = $('#rooms-list');
    $newRoom = $tabs.find('.new a');
    eu = window.encodeURIComponent;
    org = room;
    rooms = new Rooms(room);
    $roomDialogue = function() {
      return $chat.find(rooms.currentSelector());
    };
    $roomTab = function() {
      return $tabs.find(rooms.currentSelector());
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
      $tabs.append("<li class=\"" + (rooms.domClass(room)) + "\"><a href=\"#\" class=\"room\">" + room + "</a><a href=\"#\" class=\"close\">x<li>");
      return $("<div class=\"dialogue " + (rooms.domClass(room)) + "\"></div>").hide().appendTo($chat);
    };
    goToRoom = function(room) {
      var isNew;
      isNew = !rooms.hasRoom(room);
      $roomDialogue().hide();
      $roomTab().removeClass("active");
      if (isNew) {
        addRoom(room);
      }
      rooms.switchRoom(room);
      $roomTab().addClass("active");
      $roomDialogue().show();
      if (isNew) {
        return $.get("/api/org/" + (eu(org)) + "/room/" + (eu(room)) + "/chats", function(chats) {
          return addChats(chats);
        });
      }
    };
    closeRoom = function(room) {
      var $dialogue, $tab;
      $tab = $tabs.find(rooms.selector(room));
      $dialogue = $chat.find(rooms.selector(room));
      if ($tab.hasClass('active')) {
        goToRoom(rooms.closest(room));
      }
      $tab.remove();
      return $dialogue.remove();
    };
    now.ready(function() {
      now.joinRoom(room);
      $.get("/api/org/" + (eu(org)) + "/room/" + rooms.current + "/chats", function(chats) {
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
      now.pub(org, rooms.current, user.email, $input.val());
      return $input.val("");
    };
    $input.enter(pub);
    $("#send").click(pub);
    $chat.delegate('a.hashtag', 'click', function(e) {
      e.preventDefault();
      return goToRoom(this.innerText);
    });
    $chat.delegate('.name a', 'click', function(e) {
      e.preventDefault();
      return goToRoom(this.innerText);
    });
    $tabs.delegate('li a.close', 'click', function(e) {
      e.preventDefault();
      return closeRoom($(this).closest('li').find(".room").text());
    });
    $tabs.delegate('li a.room', 'click', function(e) {
      e.preventDefault();
      return goToRoom($(this).text());
    });
    $tabs.find(".new a").hover(function(e) {
      e.preventDefault();
      return $(this).find(".join").show("fast");
    });
    roomListOpen = false;
    $newRoom.hover(function(e) {
      return $newRoom.find(".join").show("fast");
    }, function(e) {
      if (!roomListOpen) {
        return $newRoom.find(".join").hide("fast");
      }
    });
    $tabs.find(".new a").click(function(e) {
      var position;
      roomListOpen = true;
      e.preventDefault();
      position = $(this).position();
      return $.get("/api/org/" + org + "/rooms", function(rooms) {
        return $roomsList.empty().append(_.reduce(rooms, (function(m, room) {
          return "" + m + "<li><a href=\"#\">" + room + "</a></li>";
        }), "")).css({
          top: (position.top + 30) + 'px',
          left: (position.left - 4) + 'px'
        }).show();
      });
    });
    $roomsList.bind("mouseleave", function(e) {
      roomListOpen = true;
      $roomsList.hide();
      return $newRoom.find(".join").hide("fast");
    });
    return $input.focus();
  };
}).call(this);
