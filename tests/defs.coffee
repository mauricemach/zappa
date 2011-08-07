zappa = require('./support/tester') require('../src/zappa')

module.exports =
  foo: ->
    t = zappa ->
      def foo: 'bar'
      get '/': -> foo
      
    t.get '/', 'bar'
    
  sum: ->
    t = zappa ->
      def sum: (a, b) -> a + b
      get '/': -> String(sum 1, 2)
      
    t.get '/', '3'
    
  byvalue: ->
    t = zappa ->
      def counter: 0
      get '/': ->
        counter++
        String(counter)
      
    t.get '/', '1'
    t.get '/', '1'
    t.get '/', '1'
    
  byref: ->
    t = zappa ->
      def foo: {counter: 0}
      get '/': ->
        foo.counter++
        String(foo.counter)
      
    t.get '/', '3'
    t.get '/', '2'
    t.get '/', '1'
