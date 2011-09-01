zappa = require '../src/zappa'
port = 15300

@tests =
  string: (t) ->
    t.expect 'body'
    
    zapp = zappa port++, ->
      def foo: 'bar'
      get '/': -> foo
    
    c = t.client(zapp.app)  
    c.get '/', (err, res) ->
      t.equal 'body', res.body, 'bar'

  function: (t) ->
    t.expect 'body'
    
    zapp = zappa port++, ->
      def sum: (a, b) -> a + b
      get '/': -> String(sum 1, 2)
    
    c = t.client(zapp.app)  
    c.get '/', (err, res) ->
      t.equal 'body', res.body, '3'

  'by value': (t) ->
    t.expect 1, 2
    
    zapp = zappa port++, ->
      def counter: 0
      get '/': ->
        counter++
        String(counter)
    
    c = t.client(zapp.app)  
    c.get '/', (err, res) ->
      t.equal 1, res.body, '1'
      c.get '/', (err, res) ->
        t.equal 2, res.body, '1'

  'by reference': (t) ->
    t.expect 1, 2
    
    zapp = zappa port++, ->
      def foo: {counter: 0}
      get '/': ->
        foo.counter++
        String(foo.counter)
    
    c = t.client(zapp.app)  
    c.get '/', (err, res) ->
      t.equal 1, res.body, '1'
      c.get '/', (err, res) ->
        t.equal 2, res.body, '2'