
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

var formattedTime = function() {
  var d = new Date(), h = d.getHours(), hours = (h > 12) ? (h - 12) : h;
  return hours + ":" + twoDigits(d.getMinutes()) + ":" + twoDigits(d.getSeconds())
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
})();

