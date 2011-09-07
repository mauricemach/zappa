require('../src/zappa') ->
  @enable 'default layout'
  
  sleep = (secs, cb) ->
    setTimeout cb, secs * 1000

  @get '/': -> @redirect '/bar'

  @get '/:foo': ->
    @data.foo += '!'
    sleep 3, =>
      @data.foo += '?'
      @render 'index'

  @view index: ->
    @title = 'Async example'
    
    h1 'Async'
    p @data.foo
