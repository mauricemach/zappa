def sleep: (secs, cb) ->
  setTimeout cb, secs * 1000

get
  '/': -> redirect '/bar'

  '/:foo': ->
    @foo += '?'
    sleep 5, =>
      @foo += '!'
    
      @title = 'Async'
      render 'default'

view ->
  h1 @title
  p @foo
