zappa = require('./support/tester') require('../src/zappa')
assert = require 'assert'

module.exports =
  'Externals: available at the root scope': ->
    t = zappa {assert, foo: 'bar'}, ->
      assert.eql foo, 'bar'

  'Externals: available at the request scope': ->
    t = zappa {foo: 'bar'}, ->
      get '/': -> foo
      
    t.get '/', 'bar'

  'Externals: shadowed by defs': ->
    t = zappa {foo: 'bar'}, ->
      def foo: 'zag'
      get '/': -> foo
      
    t.get '/', 'zag'

  'Externals: shadowed by helpers': ->
    t = zappa {foo: 'bar'}, ->
      helper foo: -> 'pong'
      get '/': -> foo()
      
    t.get '/', 'pong'

  'Externals: shadow globals': ->
    t = zappa {__filename: 'shadowglobals.coffee'}, ->
      get '/': -> __filename
      
    t.get '/', 'shadowglobals.coffee'

  'Externals: shadow root scope variables': ->
    t = zappa {assert, get: 'got'}, ->
      assert.eql get, 'got'

  'Externals: primitives are passed by value': ->
    foo = 'bar'
    t = zappa {foo}, ->
      get '/': -> foo
    foo += '!'
      
    t.get '/', 'bar'

  'Externals: objects are passed by reference': ->
    foo = {zig: 'zag'}
    t = zappa {foo}, ->
      get '/': -> foo.zig
    foo.zig += '!'
      
    t.get '/', 'zag!'