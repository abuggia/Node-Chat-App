(function() {
  var app, assert, assert_post_status;
  assert = require('assert');
  app = require('../app.coffee');
  assert_post_status = function(url, data, status) {
    return assert.response(app, {
      url: url,
      method: 'POST',
      data: data,
      headers: {
        'content-type': 'application/x-www-form-urlencoded'
      }
    }, {
      status: status
    });
  };
  module.exports = {
    'backoff messages': function(done) {
      assert_post_status("/users", "user[email]=abuggia@gmail.com", 403);
      assert_post_status("/users", "user[email]=dude@bu.edu", 420);
      return done(function() {
        return console.log("completed");
      });
    }
  };
}).call(this);
