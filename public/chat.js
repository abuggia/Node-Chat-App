(function() {
  var Rooms;
  Rooms = (function() {
    function Rooms() {
      this.ids = {};
      this._ids = _(this.ids).chain();
      this.current = void 0;
      this.last = 0;
    }
    Rooms.prototype.has = function(name) {
      return this.ids[name] != null;
    };
    Rooms.prototype.add = function(name) {
      return this.ids[name] = ++this.last;
    };
    Rooms.prototype.remove = function(name) {
      return delete this.ids[name];
    };
    Rooms.prototype["switch"] = function(name) {
      return this.current = name;
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
  window.initChat = function(org, user, roomsList, currentRoom) {
    var $chat, $roomDialogue, $roomTab, $roomsList, $tabs, addChat, addChats, addRoom, closeRoom, footerHeight, goToRoom, headerHeight, init, margin, pub, resizeChat, roomListOpen, rooms, _ref;
    $chat = $('#chat');
    $tabs = $('#tabs');
    $roomsList = $('#rooms-list');
    rooms = new Rooms();
    $roomDialogue = function() {
      return $$("#chat " + (rooms.currentSelector()));
    };
    $roomTab = function() {
      return $$("#tabs " + (rooms.currentSelector()));
    };
    addChat = function(name, email, text, time) {
      $render('single-chat', {
        name: name,
        text: text,
        time: time,
        email: email,
        linkName: email !== user.email
      }).appendTo($roomDialogue());
      return $chat.scrollTop(1000000);
    };
    addChats = function(chats) {
      var c, _i, _len, _results;
      chats.reverse();
      _results = [];
      for (_i = 0, _len = chats.length; _i < _len; _i++) {
        c = chats[_i];
        _results.push(addChat(c.handle, c.user, c.text, formatTime(c.created_at)));
      }
      return _results;
    };
    addRoom = function(room, loadingFromSession) {
      var $tab, data;
      if (loadingFromSession == null) {
        loadingFromSession = false;
      }
      rooms.add(room);
      data = {
        room: room,
        domClass: rooms.domClass(room)
      };
      $tab = $render('room-tab', data).hide().insertBefore($$("#tabs li.new"));
      $tab.slideOut($tab.innerWidth());
      $render('dialogue-window', data).hide().appendTo($$("#chat"));
      if (!loadingFromSession) {
        return api.addRoomToSession(room);
      }
    };
    goToRoom = function(room) {
      $roomDialogue().hide();
      $roomTab().removeClass("active");
      if (!rooms.has(room)) {
        addRoom(room);
      }
      rooms["switch"](room);
      $roomTab().addClass("active");
      $roomDialogue().show();
      now.joinRoom(rooms.current);
      $roomDialogue().empty();
      api.chats(org, rooms.current, function(chats) {
        return addChats(chats);
      });
      return now.withUsersInRoom(rooms.current, function(users) {
        return $$("#users").html(render("user-list-items", {
          list: users
        }));
      });
    };
    closeRoom = function(room) {
      if ($$("#tabs " + (rooms.selector(room))).hasClass('active')) {
        goToRoom(rooms.closest(room));
      }
      $$("#tabs " + (rooms.selector(room))).remove();
      $$("#chat " + (rooms.selector(room))).remove();
      rooms.remove(room);
      now.leaveRoom(room);
      return api.removeRoomFromSession(room);
    };
    pub = function() {
      now.pub(org, rooms.current, user.email, user.handle, $$("#enter input").val());
      return $$("#enter input").val('');
    };
    _ref = [33, 40, 16], headerHeight = _ref[0], footerHeight = _ref[1], margin = _ref[2];
    resizeChat = function() {
      $("#chat").height($$("body").height() - headerHeight - footerHeight - margin).scrollTop(1000000);
      return $$("#enter input").width($$("#enter").width() - 100);
    };
    $$('#enter input').enter(pub);
    $('#enter button').clickWithoutDefault(pub);
    $chat.dclick('a.hashtag', function($this) {
      return goToRoom($this.text());
    });
    $chat.dclick('.name a', function($this) {
      return goToRoom($this.text());
    });
    $tabs.dclick('li a.close', function($this) {
      return closeRoom($this.closest('li').find(".room").text());
    });
    $tabs.dclick('li a.room', function($this) {
      return goToRoom($this.text());
    });
    $('a#logout').clickWithoutDefault(function() {
      return api.logout();
    });
    $$('#users').dclick('.user', function($this) {
      if ($this.text() !== user.handle) {
        return goToRoom($this.text());
      }
    });
    $(window).resize(resizeChat);
    $$('#top-right a.avatar').clickWithoutDefault(function($this) {
      return $$('#top-right .options').show();
    });
    $tabs.find(".new").hover(function() {
      return $(this).animate({
        width: "180px"
      });
    }, function() {
      return $(this).animate({
        width: "47px"
      });
    });
    roomListOpen = false;
    $$('#tabs .new a').hover(function() {
      return $$('#tabs .rooms-list input').slideOut(110);
    }, function() {
      if (!roomListOpen) {
        return $$('#tabs .rooms-list input').animate({
          width: 0
        }, {
          queue: false,
          duration: 450
        });
      }
    });
    $$('#tabs .new a').clickWithoutDefault(function($this) {
      roomListOpen = true;
      return api.rooms(org, function(list) {
        $$('#rooms-list').html(render('rooms-list-items', {
          list: _.reject(list, function(room) {
            return rooms.has(room.name);
          })
        }));
        $$('#rooms-list').show();
        return $$('#rooms-list input').focus();
      });
    });
    $$('#tabs .new').bind("mouseleave", function() {
      $roomsList.hide();
      return roomListOpen = false;
    });
    $$('#rooms-list').dclick('li a', function($this) {
      $roomsList.hide();
      return goToRoom($this.find('.roomName').text());
    });
    $$('#rooms-list').delegate('input', 'keydown', function(e) {
      var code;
      code = keyCode(e);
      if (!codeIsLetter(code) && !codeIsNumber(code) && code !== 8) {
        return e.preventDefault();
      }
    });
    $$('#rooms-list').delegate('input', 'keyup', function(e) {
      var code;
      code = keyCode(e);
      if (code === 13) {
        e.preventDefault();
        $roomsList.hide();
        return goToRoom('#' + $(this).val());
      }
    });
    now.name = user.handle;
    now.email = user.email;
    now.sub = function(room, name, email, text) {
      if (room === rooms.current) {
        return addChat(name, email, text, formattedTime());
      }
    };
    init = false;
    now.ready(function() {
      var r, _i, _len;
      if (!init) {
        for (_i = 0, _len = roomsList.length; _i < _len; _i++) {
          r = roomsList[_i];
          addRoom(r, true);
        }
        goToRoom(currentRoom);
        resizeChat();
        return init = true;
      }
    });
    return $$("#enter input").focus();
  };
}).call(this);
