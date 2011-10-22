
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

(function() {

  var keyCode = function(e) {
    return (e.keyCode ? e.keyCode : e.which);
  };

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

})();

