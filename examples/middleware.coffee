require('zappa') ->
  @use @app.router, 'static', static: "#{__dirname}/views"
  
  @get '/index.jade': 'incercepted by a route!'
  
  @get '/': -> @redirect '/foo.txt'