require('../src/zappa') ->
  @enable 'serve jquery'
  
  @get '/': ->
    @render index: {layout: no}
  
  @on 'set nickname': ->
    @client.nickname = @data.nickname
  
  @on said: ->
    @broadcast said: {nickname: @client.nickname, text: @data.text}
    @emit said: {nickname: @client.nickname, text: @data.text}
  
  @client '/index.js': ->
    @connect()

    @on said: ->
      $('#panel').append "<p>#{@data.nickname} said: #{@data.text}</p>"
    
    $().ready =>
      @emit 'set nickname', nickname: prompt('Pick a nickname')
      
      $('button').click =>
        @emit 'said', text: $('#box').val()
        $('#box').val('').focus()
    
  @view index: ->
    doctype 5
    html ->
      head ->
        title 'PicoChat!'
        script src: '/socket.io/socket.io.js'
        script src: '/zappa/jquery.js'
        script src: '/zappa/zappa.js'
        script src: '/index.js'
      body ->
        div id: 'panel'
        input id: 'box'
        button 'Send'