require('./src/zappa') ->
  @enable 'default layout'
  
  @set views: __dirname + '/tests/views'

  @get '/': ->
    @render index: {foo: 'bong'}
  
  @view index: ->
    @title = 'shaboo'
    p 'inline view'
    p @foo