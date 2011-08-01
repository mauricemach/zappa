require('zappa') ->
  get '/': ->
    render 'index', layout: no
  
  at 'set nickname': ->
    client.nickname = @nickname
  
  at said: ->
    io.sockets.emit 'said', nickname: client.nickname, text: @text
  
  client '/index.js': ->
    connect()

    at said: ->
      $('#panel').append "<p>#{@nickname} said: #{@text}</p>"
    
    $().ready ->
      emit 'set nickname', nickname: prompt('Pick a nickname')
      
      $('button').click ->
        emit 'said', text: $('#box').val()
        $('#box').val('').focus()
    
  view index: ->
    doctype 5
    html ->
      head ->
        title 'PicoChat!'
        script src: '/socket.io/socket.io.js'
        script src: 'http://ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.min.js'
        script src: '/zappa/zappa.js'
        script src: '/index.js'
      body ->
        div id: 'panel'
        input id: 'box'
        button 'Send'