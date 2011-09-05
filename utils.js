
var crypto = require('crypto');

var chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz";
exports.randomString = function(length) {
	var ret = '';
	for (var i=0; i < length; i++) {
		var rnum = Math.floor(Math.random() * chars.length);
		ret += chars.substring(rnum,rnum+1);
	}
  return ret;
}

exports.hash = function(msg, key) {
  return crypto.createHmac('sha256', key).update(msg).digest('hex');
}

