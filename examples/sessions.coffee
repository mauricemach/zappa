require('../src/zappa') ->
  @use 'cookieParser', session: {secret: 'foo'}

  @get '/': ->
    @render 'index', {user: @session.user}
    
  @get '/login': ->
    @session.user = 'foo'
    @redirect '/'
    
  @get '/logout': ->
    @session.user = null
    @redirect '/'
    
  @view index: ->
    p '@user: ' + (@user or 'null')
    p -> a href: '/login', 'login'
    p -> a href: '/logout', 'logout'