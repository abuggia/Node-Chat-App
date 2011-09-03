
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

var fn = function() {
  var args = arguments
  var rest = [].splice.call(args, 1, args.length - 1)
  return function() { args[0].apply(this, rest); }
};

var formattedTime = function() {
  var d = new Date();
  var hours = (d.getHours() > 12) ? (d.getHours() - 12) : d.getHours();
  var minutes = (d.getMinutes() < 10) ? '0' + d.getMinutes() : d.getMinutes();
  return hours + ":" + minutes + ":" + d.getSeconds();
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
  };
})();

