assert = require 'assert'

class Tester
  constructor: (zappa, args) ->
    @app = zappa.app.apply(zappa, args).app

  response: (req, res, name) ->
    assert.response @app, req, res, name

  get: (url, body, name) ->
    assert.response @app, {url}, {body}, name
    
module.exports = (zappa) ->
  (args...) ->
    new Tester(zappa, args)