zappa = require('./support/tester') require('../src/zappa')

module.exports =
  'Middleware with vanilla express API': ->
    t = zappa {__dirname}, ->
      app.use express.static(__dirname + '/public')
    
    t.get '/foo.txt', 'bar'

  'Middleware with `use`': ->
    t = zappa {__dirname}, ->
      use express.static(__dirname + '/public'), express.responseTime()
    
    t.get '/foo.txt', 'bar'
    t.response {url: '/'}, {headers: {'X-Response-Time': /\d+ms/}}

  'Middleware with `use` and shortcuts': ->
    t = zappa {__dirname}, ->
      use static: __dirname + '/public', 'responseTime'
    
    t.get '/foo.txt', 'bar'
    t.response {url: '/'}, {headers: {'X-Response-Time': /\d+ms/}}

  'Middleware with `use`, shortcuts and zappa added defaults': ->
    t = zappa ->
      use 'static', 'responseTime'
    
    t.get '/foo.txt', 'bar'
    t.response {url: '/'}, {headers: {'X-Response-Time': /\d+ms/}}

  'Middleware precedence': ->
    t = zappa ->
      use app.router, 'static'
      get '/foo.txt': 'intercepted!'
    
    t.get '/foo.txt', 'intercepted!'