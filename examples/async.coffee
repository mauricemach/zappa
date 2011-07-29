require('../src/zappa').run ->
  def sleep: (secs, cb) ->
    setTimeout cb, secs * 1000

  get '/': -> redirect '/bar'

  get '/:foo': ->
    @foo += '!'
    sleep 3, =>
      @foo += '?'
      render 'index'

  view index: ->
    h1 'Async'
    p @foo
