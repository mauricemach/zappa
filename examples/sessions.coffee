require('zappa') ->
  use 'cookieParser', session: {secret: 'foo'}

  get '/': ->
    @user = session.user
    render 'index'
    
  get '/login': ->
    session.user = 'foo'
    redirect '/'
    
  get '/logout': ->
    session.user = null
    redirect '/'
    
  view index: ->
    p '@user: ' + (@user or 'null')
    p -> a href: '/login', 'login'
    p -> a href: '/logout', 'logout'