def sleep: (secs, cb) ->
  setTimeout cb, secs * 1000

get
  '/': -> redirect '/sync/bar'

  '/async/:foo': ->
    @foo += '?'
    sleep 5, =>
      @foo += '!'
    
      @title = 'Async'
      render 'index'

  '/sync/:foo': ->
    @foo += '?'
    sleep 5, =>
      @foo += '!'
    
      @title = 'Sync'
      render 'index'

view index: ->
  h1 @title
  p @foo
