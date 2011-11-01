
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
  var h = d.getHours(), hours = (h > 12) ? (h - 12) : h;
  return hours + ":" + twoDigits(d.getMinutes()) + ":" + twoDigits(d.getSeconds())
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
      fn.call(this);
    });
  };

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
      $.get("/api/org/" + eu(org) + "/room/" + eu(room) + "/chats", function(data) { fn(data); });
    },
    rooms: function(org, fn) {
      $.get("/api/org/" + org + "/rooms", function(data) { fn(data); });
    }
  }
}();
