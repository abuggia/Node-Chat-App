
_ = require("underscore")

class NotFound extends Error
  code: 404

class NotReady extends Error
  code: 420

class Forbidden extends Error
  code: 403

class Conflict extends Error
  code: 409

module.exports.NotFound = NotFound
module.exports.NotReady = NotReady
module.exports.Forbidden = Forbidden 
module.exports.Conflict = Conflict 

module.exports.defined = (err) ->
  _.detect [ NotFound, NotReady, Forbidden, Conflict ], (klass) -> err instanceof klass



