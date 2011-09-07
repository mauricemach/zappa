require('./src/zappa') ->
  @helper sum: (a, b) ->
    (a + b + @ble).toString()
    
  subtract = (a, b) ->
    (a - b).toString()
  
  @get '/': ->
    @redirect '/ohai'
    
  @get '/context_as_param': (c) ->
    c.send 'context_as_param'
    
  @get '/ohai': ->
    #@ble = 5
    #subtract 17, 5
    @render 'index'
  
  @on connection: ->
    @emit 'welcome'
    
  @on shout: ->
    @broadcast 'shouted'
    
  @view index: ->
    h1 'fooa'
  
  @view layout: ->
    doctype 5
    html ->
      head ->
        title 'foo'
      script src: '/socket.io/socket.io.js'
      coffeescript ->
        window.onload = ->
          socket = io.connect 'http://localhost'
          
          socket.on 'welcome', ->
            console.log 'welcome'
      body @body