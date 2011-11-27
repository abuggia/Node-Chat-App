/*
 * JavaScript Pretty Date
 * Copyright (c) 2011 John Resig (ejohn.org)
 * Licensed under the MIT and GPL licenses.
 */

// Takes an ISO time and returns a string representing how
// long ago the date represents.
function prettyDate(time, defaultDisplay){
	var date = new Date((time || "").replace(/-/g,"/").replace(/[TZ]/g," ")),
		diff = (((new Date()).getTime() - date.getTime()) / 1000),
		day_diff = Math.floor(diff / 86400);
			
	if ( isNaN(day_diff) || day_diff < 0 || day_diff >= 31 )
		return defaultDisplay;
			
	return day_diff == 0 && (
			diff < 60 && "just now" ||
			diff < 120 && "1 minute ago" ||
			diff < 3600 && Math.floor( diff / 60 ) + " minutes ago" ||
			diff < 7200 && "1 hour ago" ||
			diff < 86400 && Math.floor( diff / 3600 ) + " hours ago") ||
		day_diff == 1 && "Yesterday" ||
		day_diff < 7 && day_diff + " days ago" ||
		day_diff < 31 && Math.ceil( day_diff / 7 ) + " weeks ago";
}



// jQuery selector caching.  Got from:  https://github.com/mape/node-express-boilerplate/blob/master/public/js/jquery.client.js
var $$ = (function() {
		var cache = {};
		return function(selector) {
			if (!cache[selector]) {
				cache[selector] = $(selector);
			}
			return cache[selector];
		};
})();

var ShowMe = function() {
  var $elems = {};

  var addIfNotSeen = function(e) { 
    if (!$elems[e]) { $elems[e] = $(e) }
    return $elems[e];
  };
 
  var notIn = function(x, list) {
    for (var i = 0; i < list.length; i++) {
      if (list[i] === x) return false;
    }
    return true;
  }

  var hideAllExcept = function(except) {
    $.each($elems, function(key, $value) { 
      if (notIn(key, except)) { 
        $value.hide();
      }
    });
  };

  var show = function() {
    hideAllExcept(arguments);
    $.each(arguments, function(index, e) {
      addIfNotSeen(e).show();
    });
  };

  show.apply(this, arguments);
  return show;
};

var twoDigits = function(num) {
  return num < 10 ? '0' + num : num;
};

var formatTime = function(d) {
  d = (d instanceof Date) ? d : new Date(d);
  var h = d.getHours(), hours = (h > 12) ? (h - 12) : (h === 0) ? 12 : h, meridian = (h > 11) ? 'pm' : 'am';
  return hours + ":" + twoDigits(d.getMinutes()) + meridian
};

var formattedTime = function() {
  return formatTime(new Date());
};

var keyCode = function(e) {
  return (e.keyCode ? e.keyCode : e.which);
};

var codeIsLetter = function(code) {
  return code >= 65 && code <= 90;
};

var codeIsNumber = function(code) {
  return code >= 48 && code <= 57;
};

(function() {

  $.fn.enter = function(fn) {
    this.keyup(function(e) {
      if (keyCode(e) === 13) {
        e.preventDefault();
        fn();
      }
    });

    return this;
  };

  $.fn.dclick = function (selector, fn) {
    this.delegate(selector, 'click', function(e) {
      e.preventDefault();
      fn.call(this, $(this));
    });
  };

  $.fn.clickWithoutDefault = function (fn) {
    this.click(function(e) {
      e.preventDefault();
      fn($(this));
    });
  }

  $.fn.moveDownLeftOf = function(down, left, of) {
    pos = $(of).offset();
    this.css( {top: (pos.top + down) + 'px', left: (pos.left + left) + 'px' } );
    return this;
  };

  $.fn.slideOut = function(width) {
    this.css({width:0});
    this.show();
    this.animate({width: width + 'px'}, {queue:false, duration:150})
  };

  $.fn.slideIn = function() {
    t = this;
    t.animate({width: 0}, {queue:false, duration:250, complete: function() { t.hide() }});
  };

  $.fn.addError = function(msg) {
    this.find('.error').html(msg);
    return this;
  }

  $.fn.clearError = function(msg) {
    this.find('.error').html('');
    return this;
  };

  $.fn.prettyDate = function(){
		return this.each(function(){
			var date = prettyDate(this.title);
			if ( date )
				$(this).text( date );
		});
	};

})();

var render = (function() {
  var compiled = {}

  return function(id, data) {
    if (compiled[id] === undefined) {
      compiled[id] = _.template($('#' + id).html());
    }
    return compiled[id](data)
  };
})();

// return a jQuery object instead of raw HTML
var $render = function(id, data) { return $(render(id, data)) };

var api = function() {
  var eu = window.encodeURIComponent

  return {
    chats: function(org, room, fn) {
      $.get("/api/org/" + eu(org) + "/room/" + eu(room) + "/chats", fn);
    },
    rooms: function(org, fn) {
      $.get("/api/org/" + org + "/rooms", fn);
    },
    topRooms: function(org, num, fn) {
      $.get("/api/org/" + org + "/toprooms/" + num, fn);
    },
    roomsByNewest: function(org, fn) {
      $.get("/api/org/" + org + "/roomsbynewest", fn);
    },
    userOpenedRoom: function(org, room, email, handle) {
      $.post("/api/org/" + org + "/useropenedroom", { room:room, user:email, handle: handle }).error(function(e) { console.log("Can't send update that user opened room: \n" + e) } );
    },
    addRoomToSession: function(room) {
      $.post("/api/session/room", {room: room}).error(function(e) { console.log("Can't save room to session: \n" + e) } );
    },
    changeHandle: function(email, handle, fn) {
      $.post("/api/handle/" + email + "/change_handle", {handle: handle})
        .success(function() { fn() })
        .error(function(e) { console.log("Can't update user name: \n" + e) } );
    },
    removeRoomFromSession: function(room) {
      $.ajax({
        type: 'DELETE',
        data: {room: room},
        url: "/api/session/room",
        error: function() { console.log("Can't save room to session: \n" + e) }
      });
    },
    logout: function() {
      $.ajax({
        type: 'DELETE',
        url: "/api/session",
        success: function() { window.location.href = '/' }
      });
    }
 
  }
}();
	

