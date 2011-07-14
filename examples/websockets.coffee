require('../src/zappa').run ->
  get '/': -> render 'index'

  get '/counter': -> "# of messages so far: #{app.counter}"

  at connection: ->
    app.counter ?= 0
    console.log "Connected: #{id}"
    broadcast 'connected', id: id

  at disconnect: ->
    console.log "Disconnected: #{id}"

  at said: ->
    console.log "#{id} said: #{@text}"
    app.counter++
    send 'said', id: id, text: @text
    broadcast 'said', id: id, text: @text

  client '/index.js': ->
    $(document).ready ->
      connect 'http://localhost'

      at connection: -> $('#log').append '<p>Connected</p>'
      at disconnect: -> $('#log').append '<p>Disconnected</p>'
      at welcome: -> $('#log').append "<p>#{@id} Connected</p>"
      at said: -> $('#log').append "<p>#{@id}: #{@text}</p>"

      $('form').submit ->
        emit said: {text: $('#box').val()}
        $('#box').val('').focus()
        false

      $('#box').focus()

  view index: ->
    @title = 'Nano Chat'
    @scripts = ['http://code.jquery.com/jquery-1.4.3.min', '/socket.io/socket.io', '/default']

    h1 @title
    div id: 'log'
    form ->
      input id: 'box'
      button id: 'say', -> 'Say'