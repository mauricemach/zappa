(function() {
  var assert, zappa;
  zappa = require('../src/zappa');
  assert = require('assert');
  exports.Tester = (function() {
    function Tester(func) {
      this.app = zappa.app(func).app;
      this.app.set('views', __dirname + '/views');
    }
    Tester.prototype.response = function(req, res, name) {
      return assert.response(this.app, req, res, name);
    };
    Tester.prototype.get = function(url, body, name) {
      return assert.response(this.app, {
        url: url
      }, {
        body: body
      }, name);
    };
    return Tester;
  })();
}).call(this);
