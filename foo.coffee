require('./src/zappa') ->
  @enable 'default layout', 'autoimport', 'autoexport'

  sleep = (secs, cb) ->
    setTimeout cb, secs * 1000

  @get '/': -> @redirect '/bar'

  @get '/:foo': ->
    @foo += 'a'
    sleep 3, =>
      @foo += 'b'
      @render 'index'

  @view index: ->
    @title = 'Async example'
    
    h1 'Async'
    p @foo
