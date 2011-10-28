(function() {
  var Rooms, resizeChat;
  Rooms = (function() {
    function Rooms(first) {
      this.ids = {};
      this.ids[first] = 1;
      this._ids = _(this.ids).chain();
      this.current = first;
      this.last = 1;
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
  resizeChat = function() {
    var button, footer, header, height, margin;
    height = $("body").height();
    header = 33;
    footer = 40;
    margin = 16;
    $("#chat").height(height - header - footer - margin);
    $("#chat").scrollTop(1000000);
    button = 100;
    return $("#enter input").width($("#enter").width() - button);
  };
  window.initChat = function(org, user) {
    var $bus, $chat, $input, $roomDialogue, $roomTab, $roomsList, $tabs, $users, addChat, addChats, addRoom, closeRoom, goToRoom, pub, roomListOpen, room_input, rooms;
    $input = $('#enter input');
    $users = $('#users');
    $chat = $('#chat');
    $tabs = $('#tabs');
    $roomsList = $('#rooms-list');
    $bus = $(document);
    rooms = new Rooms(org);
    resizeChat();
    $(window).resize(function() {
      return resizeChat();
    });
    $roomDialogue = function() {
      return $$("#chat " + (rooms.currentSelector()));
    };
    $roomTab = function() {
      return $$("#tabs " + (rooms.currentSelector()));
    };
    addChat = function(name, text, time) {
      $render('single-chat', {
        name: name,
        text: text,
        time: time
      }).appendTo($roomDialogue());
      return $chat.scrollTop(1000000);
    };
    addChats = function(chats) {
      var c, _i, _len, _results;
      chats.reverse();
      _results = [];
      for (_i = 0, _len = chats.length; _i < _len; _i++) {
        c = chats[_i];
        _results.push(addChat(c.user, c.text, formatTime(c.created_at)));
      }
      return _results;
    };
    addRoom = function(room) {
      var $tab, data;
      rooms.add(room);
      data = {
        room: room,
        domClass: rooms.domClass(room)
      };
      $tab = $render('room-tab', data).hide().insertBefore($$("#tabs li.new"));
      $tab.slideOut($tab.width());
      return $render('dialogue-window', data).hide().appendTo($$("#chat"));
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
      return $bus.trigger("room-changed");
    };
    closeRoom = function(room) {
      if ($$("#tabs " + (rooms.selector(room))).hasClass('active')) {
        goToRoom(rooms.closest(room));
      }
      $$("#tabs " + (rooms.selector(room))).remove();
      $$("#chat " + (rooms.selector(room))).remove();
      return rooms.remove(room);
    };
    pub = function() {
      now.pub(org, rooms.current, user.email, $input.val());
      return $input.val("");
    };
    $bus.bind('room-changed', function() {
      var user_view;
      now.joinRoom(rooms.current);
      $roomDialogue().empty();
      api.chats(org, rooms.current, function(chats) {
        return addChats(chats);
      });
      now.eachUserInRoom(rooms.current, function(user) {});
      user_view = $render("user-list-item", {
        user: user
      });
      return $$("#users").append(user_view);
    });
    $input.enter(pub);
    $('#enter button').click(pub);
    $chat.dclick('a.hashtag', function() {
      return goToRoom($(this).text());
    });
    $chat.dclick('.name a', function() {
      return goToRoom($(this).text());
    });
    $tabs.dclick('li a.close', function() {
      return closeRoom($(this).closest('li').find(".room").text());
    });
    $tabs.dclick('li a.room', function() {
      return goToRoom($(this).text());
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
    room_input = $$('#tabs .rooms-list input');
    $$('#tabs .new a').hover(function() {
      return room_input.slideOut(110);
    }, function() {
      if (!roomListOpen) {
        return room_input.animate({
          width: 0
        }, {
          queue: false,
          duration: 450
        });
      }
    });
    $$('#tabs .new a').click(function(e) {
      var $this;
      roomListOpen = true;
      $this = $(this);
      api.rooms(org, function(list) {
        $$('#rooms-list').html(render('rooms-list-items', {
          list: _.reject(list, function(room) {
            return rooms.has(room);
          })
        }));
        $$('#rooms-list').show();
        return $$('#rooms-list input').focus();
      });
      return e.preventDefault();
    });
    $$('#tabs .new').bind("mouseleave", function() {
      $roomsList.hide();
      return roomListOpen = false;
    });
    $$('#rooms-list').dclick('li a', function() {
      $roomsList.hide();
      return goToRoom($(this).text());
    });
    $$('#rooms-list').delegate('input', 'keydown', function(e) {
      var code;
      code = keyCode(e);
      if (code === 32) {
        return e.preventDefault();
      }
    });
    $$('#rooms-list').delegate('input', 'keyup', function(e) {
      var code;
      code = keyCode(e);
      if (code === 13) {
        e.preventDefault();
        $roomsList.hide();
        $$('#tabs .join').hide();
        return goToRoom($(this).val());
      }
    });
    now.ready(function() {
      return $bus.trigger("room-changed");
    });
    now.name = user.handle;
    now.email = user.email;
    now.sub = function(name, text) {
      return addChat(name, text, formattedTime());
    };
    $$('#users').dclick('.user', function() {
      var handle;
      handle = $(this).text();
      if (handle !== user.handle) {
        return goToRoom(handle);
      }
    });
    return $input.focus();
  };
}).call(this);
