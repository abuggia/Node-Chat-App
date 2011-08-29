

var DisplayRegister = function() {
  var $elems = {};

  var get = function () { return $elems[e] };

  var hide = function(except) {
    $.each($elems, function(key, $value) { 
      if (except !== key) { 
        $value.hide() 
      }
    });
  };

  var show = function() {
    hide();
    $.each(arguments, function(index, e) {
      if ($elems[e] === undefined) {
        $elems[e] = $(e);
      }
      $elems[e].show();
    });
  };

  show(arguments[0]);
  return { 'show': show, 'get': get };
};

$.fn.onEnter = function(fn) {
  var keyCode = function(e) {
    return (e.keyCode ? e.keyCode : e.which);
  };

  this.keypress(function(e) {
    if (keyCode(e) === 13) {
      e.preventDefault();
      fn();
    }
  });
};

 
