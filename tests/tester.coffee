zappa = require 'zappa'
assert = require 'assert'

class exports.Tester
  constructor: (func) ->
    @app = zappa.app(func).app
    @app.set 'views', __dirname + '/views'

  response: (req, res, name) ->
    assert.response @app, req, res, name

  get: (url, body, name) ->
    assert.response @app, {url}, {body}, name