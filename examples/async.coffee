require('zappa') ->
  enable 'default layout'
  
  def sleep: (secs, cb) ->
    setTimeout cb, secs * 1000

  get '/': -> redirect '/bar'

  get '/:foo': ->
    @foo += '!'
    sleep 3, =>
      @foo += '?'
      render 'index'

  view index: ->
    @title = 'Async example'
    
    h1 'Async'
    p @foo
