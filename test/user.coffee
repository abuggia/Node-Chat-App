assert = require('assert')
app = require('../app.coffee')

assert_post_status = (url, data, status) -> 
  assert.response(app, {
    url: url
    method: 'POST'
    data: data 
    headers:
      'content-type': 'application/x-www-form-urlencoded'
    },
    { status: status })

module.exports =

  'backoff messages': (done) ->
    # not an edu address
    assert_post_status "/users", "user[email]=abuggia@gmail.com", 403

    # campus not ready yet
    assert_post_status "/users", "user[email]=dude@bu.edu" , 420

    done(() ->
      console.log "completed"
    )


