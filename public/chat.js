(function() {
  var Rooms;
  Rooms = (function() {
    function Rooms() {
      this.ids = {};
      this._ids = _(this.ids).chain();
      this.current = void 0;
      this.last = 0;
      this.lastChatAuthor = {};
      this.lastChatCell = {};
      this.users = {};
    }
    Rooms.prototype.has = function(name) {
      return this.ids[name] != null;
    };
    Rooms.prototype.add = function(name) {
      return this.ids[name] = ++this.last;
    };
    Rooms.prototype.remove = function(name) {
      delete this.ids[name];
      return this.setCell(name, void 0);
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
    Rooms.prototype.setAuthor = function(room, author) {
      return this.lastChatAuthor[room] = author;
    };
    Rooms.prototype.isSameAuthor = function(room, author) {
      var last;
      last = this.lastChatAuthor[room];
      this.setAuthor(room, author);
      return author === last;
    };
    Rooms.prototype.setCell = function(room, $cell) {
      return this.lastChatCell[room] = $cell;
    };
    Rooms.prototype.$lastCell = function(room) {
      return this.lastChatCell[room];
    };
    Rooms.prototype.usersInCurrent = function() {
      return this.users[this.current] || [];
    };
    Rooms.prototype.addUser = function(room, user) {
      if (!this.users[room]) {
        this.users[room] = [];
      }
      if (!_.find(this.users[room], function(u) {
        return u.email === user.email;
      })) {
        return this.users[room].push(user);
      }
    };
    Rooms.prototype.removeUser = function(room, user) {
      return this.users[room] = _.reject(this.users[room], function(u) {
        return u.email === user.email;
      });
    };
    Rooms.prototype.removeUserFromAll = function(user) {
      var room, _i, _len, _ref, _results;
      _ref = _.keys(this.users);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        room = _ref[_i];
        _results.push(this.removeUser(room, user));
      }
      return _results;
    };
    Rooms.prototype.addUserToAll = function(user) {
      var room, _i, _len, _ref, _results;
      _ref = _.keys(this.users);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        room = _ref[_i];
        _results.push(this.addUser(room, user));
      }
      return _results;
    };
    Rooms.prototype.setUsers = function(room, users) {
      return this.users[room] = users;
    };
    return Rooms;
  })();
  window.initChat = function(org, user, roomsList, currentRoom) {
    var $chat, $roomDialogue, $roomTab, $roomsList, $tabs, addChat, addChats, addRoom, changeName, changeNameDialogue, closeRoom, footerHeight, goToRoom, headerHeight, hideModalDialogue, increment, init, margin, modalDialogue, preventSpaces, pub, resizeChat, roomListOpen, rooms, sidePanelOffset, updateRoomLists, updateUserList, _ref;
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
    addChat = function(room, name, email, text, time, trackMentions, bot) {
      var $c, mentioned;
      if (bot) {
        if (!(bot.type === 'roomopened' && bot.room === rooms.current)) {
          $$("#chat " + (rooms.currentSelector())).append(render('bot-chat-item', {
            text: text,
            time: time
          }));
          rooms.setCell(room, void 0);
        }
      } else {
        if (!rooms.has(room)) {
          return;
        }
        mentioned = false;
        text = text.replace(new RegExp('\\b(' + user.handle + ')\\b', 'g'), function(match) {
          mentioned = true;
          return "<span class=\"handle-mention\">" + match + "</span>";
        });
        if (!rooms.isSameAuthor(room, name) || !rooms.$lastCell(rooms.current)) {
          $c = $render('single-chat', {
            name: name,
            text: text,
            time: time,
            email: email,
            yours: email === user.email
          });
          $c.appendTo($$("#chat " + (rooms.selector(room))));
          rooms.setCell(room, $c.find('td.main'));
        } else {
          rooms.$lastCell(room).append('<p class="text">' + text + '</p>');
        }
        if (trackMentions && room !== rooms.current) {
          increment($$("#tabs " + (rooms.selector(room)) + " .num-unread"));
          if (mentioned) {
            increment($$("#tabs " + (rooms.selector(room)) + " .num-mentions"));
          }
        }
      }
      return $chat.scrollTop(1000000);
    };
    increment = function($e) {
      var v;
      v = $e.text();
      if (/\D/.test(v) || !v) {
        v = 0;
      }
      return $e.text(1 + parseInt(v));
    };
    updateUserList = function() {
      var users;
      users = _.sortBy(rooms.usersInCurrent(), function(u) {
        return u.handle;
      });
      $$('#users').html(render("user-list-items", {
        list: users
      }));
      return $$('#user-count-num').text(users.length);
    };
    addChats = function(room, chats) {
      var c, _i, _len, _results;
      chats.reverse();
      _results = [];
      for (_i = 0, _len = chats.length; _i < _len; _i++) {
        c = chats[_i];
        _results.push(addChat(room, c.handle, c.user, c.text, formatTime(c.created_at), false, void 0));
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
        domClass: rooms.domClass(room),
        org: org
      };
      $tab = $render('room-tab', data).hide().insertBefore($$("#tabs li.new"));
      $tab.slideOut($tab.outerWidth() + 10);
      $render('dialogue-window', data).hide().appendTo($$("#chat"));
      api.chats(org, room, function(chats) {
        return addChats(room, chats);
      });
      if (!loadingFromSession) {
        api.addRoomToSession(room);
      }
      return now.withUsersInRoom(room, function(users) {
        if (users.length === 0) {
          api.userOpenedRoom(org, room, user.email, user.handle);
        }
        rooms.setUsers(room, users);
        return now.joinRoom(room);
      });
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
      $$("#tabs " + (rooms.selector(room)) + " .num-unread").text('');
      $$("#tabs " + (rooms.selector(room)) + " .num-mentions").text('');
      $$('#enter textarea').focus();
      $$('#chat').scrollTop(1000000);
      return $$('#users-header').text("People in " + room);
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
      now.pub(org, rooms.current, user.email, user.handle, $$("#enter textarea").val());
      return $$("#enter textarea").val('');
    };
    modalDialogue = function(content) {
      $$('#modal-dialogue-message').html(content);
      $$('#modal-dialogue').show();
      return $$('#modal-dialogue-message').clearError().show();
    };
    hideModalDialogue = function() {
      $$('#modal-dialogue').hide();
      $$('#modal-dialogue-message').hide();
      return $$('#enter textarea').focus();
    };
    changeNameDialogue = function() {
      var $d, $input;
      $d = modalDialogue(render('change-name-form'));
      $input = $d.find('input').focus();
      $d.find('button.change').click(function() {
        return changeName($input);
      });
      $input.enter(function() {
        return changeName($input);
      });
      return $input.keyup = function(e) {
        return preventSpaces(e);
      };
    };
    changeName = function($input) {
      var newName;
      newName = $input.val().replace(/\s/, '');
      if (newName.length < 1) {
        return $$('#modal-dialogue-message').addError('New name cannot be blank');
      } else {
        return api.changeHandle(user.email, newName, (function() {
          now.name = newName;
          hideModalDialogue();
          user.handle = newName;
          rooms.removeUserFromAll(user);
          rooms.addUserToAll(user);
          return updateUserList();
        }), (function() {
          return $$('#modal-dialogue-message').addError('Sorry.  This username has been taken.');
        }));
      }
    };
    preventSpaces = function(e) {
      var code;
      code = keyCode(e);
      if (!codeIsLetter(code) && !codeIsNumber(code) && code !== 8) {
        return e.preventDefault();
      }
    };
    updateRoomLists = function() {
      api.topRooms(org, 5, function(rooms) {
        return $$('#top-rooms').html(render('top-rooms-items', {
          rooms: rooms
        }));
      });
      return api.roomsByNewest(org, function(rooms) {
        return $$('#all-rooms').html(render('all-rooms-items', {
          rooms: rooms
        }));
      });
    };
    _ref = [33, 56, 22, 290], headerHeight = _ref[0], footerHeight = _ref[1], margin = _ref[2], sidePanelOffset = _ref[3];
    resizeChat = function() {
      var height;
      height = $$("body").height() - headerHeight - footerHeight - margin;
      $$("#chat").height(height).scrollTop(1000000);
      return $$("#side-panel .flex-container").height(Math.round((height - sidePanelOffset) / 2));
    };
    $$('#enter textarea').enter(pub);
    $('#enter button').clickWithoutDefault(pub);
    $chat.dclick('a.hashtag', function($this) {
      return goToRoom($this.text());
    });
    $tabs.dclick('li a.close', function($this) {
      return closeRoom($this.closest('li').find(".room .name").text());
    });
    $tabs.dclick('li a.room', function($this) {
      return goToRoom($this.find('.name').text());
    });
    $('a#logout').clickWithoutDefault(function() {
      return api.logout();
    });
    $(window).resize(resizeChat);
    $$('#top-right a.avatar').clickWithoutDefault(function($this) {
      return $$('#top-right .options').toggle();
    });
    $$('#modal-dialogue-message').dclick('button.cancel', hideModalDialogue);
    $$('#users').dclick('li a', function() {});
    $('a#change-name').clickWithoutDefault(function() {
      changeNameDialogue();
      return $$('#top-right .options').toggle();
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
      return api.topRooms(org, 10, function(list) {
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
      return preventSpaces(e);
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
    now.sub = function(room, name, email, text, bot) {
      return addChat(room, name, email, text, formattedTime(), true, bot);
    };
    now.addUser = function(room, user) {
      rooms.addUser(room, user);
      if (room === rooms.current) {
        return updateUserList();
      }
    };
    now.removeUser = function(room, user) {
      rooms.removeUser(room, user);
      if (room === rooms.current) {
        return updateUserList();
      }
    };
    now.newRoomOpened = function() {
      return updateRoomLists();
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
        updateRoomLists();
        return init = true;
      }
    });
    return $$("#enter textarea").focus();
  };
}).call(this);
