zappa = require('./support/tester') require('../src/zappa')

module.exports =
  hello: ->
    t = zappa ->
      get '/string': 'string'
      get '/return': -> 'return'
      get '/send': -> send 'send'
      get /\/regex$/, 'regex'
      get /\/regex_function$/, -> 'regex function'
    
    t.get '/string', 'string'
    t.get '/return', 'return'
    t.get '/send', 'send'
    t.get '/regex', 'regex'
    t.get '/regex_function', 'regex function'

  verbs: ->
    t = zappa ->
      post '/': 'post'
      put '/': -> 'put'
      del '/': -> send 'del'
    
    t.response {method: 'post', url: '/'}, {body: 'post'}
    t.response {method: 'put', url: '/'}, {body: 'put'}
    t.response {method: 'delete', url: '/'}, {body: 'del'}

  redirect: ->
    t = zappa ->
      get '/': -> redirect '/foo'
    
    t.response {url: '/'}, {status: 302, headers: {Location: /\/foo$/}}
    
  params: ->
    t = zappa ->
      use 'bodyParser'
      get '/:foo': -> @foo + @ping
      post '/:foo': -> @foo + @ping + @zig
    
    t.get '/bar?ping=pong', 'barpong'
    headers = 'Content-Type': 'application/x-www-form-urlencoded'
    t.response {method: 'post', url: '/bar?ping=pong', data: 'zig=zag', headers}, {body: 'barpongzag'}