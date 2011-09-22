require('../src/zappa') ->
  @enable 'default layout'

  sleep = (secs, cb) ->
    setTimeout cb, secs * 1000

  @get '/': -> @redirect '/bar'

  @get '/:foo': ->
    @params.foo += '!'
    sleep 3, =>
      @params.foo += '?'
      @render index: @params

  @view index: ->
    @title = 'Async example'
    
    h1 'Async'
    p @foo
