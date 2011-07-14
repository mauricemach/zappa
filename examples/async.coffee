require('../src/zappa').run ->
  def sleep: (secs, cb) ->
    setTimeout cb, secs * 1000

  get
    '/': -> redirect '/bar'

    '/:foo': ->
      @foo += '?'
      sleep 5, =>
        @foo += '!'
    
        @title = 'Async'
        render 'index'

  view index: ->
    h1 @title
    p @foo
