require('./src/zappa') ->
  @enable 'default layout'
  @set databag: 'param'

  @get '/': ->
    @render 'index'
  
  @on connection: ->
    @emit welcome: {motd: 'data in the param!'}
    
  @client '/index.js': ->
    @connect()
    
    @on welcome: (d) ->
      console.log 'welcome:', d.motd
  
  @view index: ->
    @title = 'Crazy zappa experiment'
    @scripts = ['/socket.io/socket.io', '/zappa/zappa', '/index']
    p @foo