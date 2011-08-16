zappa = require '../src/zappa'
port = 15400

@tests =
  'available at the root scope': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, {t, foo: 'bar'}, ->
      t.equal 1, foo, 'bar'

  'available at the request scope': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, {t, foo: 'bar'}, ->
      get '/': ->
        t.equal 1, foo, 'bar'
        
    c = t.client(zapp.app)
    c.get '/'

  'shadowed by defs': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, {t, foo: 'bar'}, ->
      def foo: 'zag'
      get '/': ->
        t.equal 1, foo, 'zag'
      
    c = t.client(zapp.app)
    c.get '/'

  'shadowed by helpers': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, {t, foo: 'bar'}, ->
      helper foo: -> 'pong'
      get '/': ->
        t.equal 1, foo(), 'pong'
      
    c = t.client(zapp.app)
    c.get '/'

  'shadow globals': (t) ->
    t.expect 'root', 'http'
    t.wait 3000
    
    zapp = zappa port++, {t, __filename: 'foo.coffee'}, ->
      t.equal 'root', __filename, 'foo.coffee'
      get '/': -> t.equal 'http', __filename, 'foo.coffee'

    c = t.client(zapp.app)
    c.get '/'

  'shadow root scope variables': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, {t, get: 'got'}, ->
      t.equal 1, get, 'got'

  'primitives are passed by value': (t) ->
    t.expect 1
    t.wait 3000

    foo = 'bar'
    zapp = zappa port++, {t, foo}, ->
      t.equal 1, foo, 'bar'
      get '/': -> t.equal 2, foo, 'bar'

    foo += '!'
    c = t.client(zapp.app)
    c.get '/'

  'objects are passed by reference': (t) ->
    t.expect 1
    t.wait 3000

    foo = {zig: 'zag'}
    zapp = zappa port++, {t, foo}, ->
      t.equal 1, foo.zig, 'zag'
      get '/': -> t.equal 2, foo.zig, 'zag!'

    foo.zig += '!'
    c = t.client(zapp.app)
    c.get '/'