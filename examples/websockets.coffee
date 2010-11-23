get '/': -> render 'default'

get '/counter': -> "# of messages so far: #{app.counter}"

at connection: ->
  app.counter ?= 0
  console.log "Connected: #{id}"
  broadcast 'connected', id: id

at disconnection: ->
  console.log "Disconnected: #{id}"

msg said: ->
  console.log "#{id} said: #{@text}"
  app.counter++
  send 'said', id: id, text: @text
  broadcast 'said', id: id, text: @text

client ->
  $(document).ready ->
    socket = new io.Socket()

    socket.on 'connect', -> $('#log').append '<p>Connected</p>'
    socket.on 'disconnect', -> $('#log').append '<p>Disconnected</p>'
    socket.on 'message', (raw_msg) ->
      msg = JSON.parse raw_msg
      if msg.connected then $('#log').append "<p>#{msg.connected.id} Connected</p>"
      else if msg.said then $('#log').append "<p>#{msg.said.id}: #{msg.said.text}</p>"

    $('form').submit ->
      socket.send JSON.stringify said: {text: $('#box').val()}
      $('#box').val('').focus()
      false

    socket.connect()
    $('#box').focus()

view ->
  @title = 'Nano Chat'
  @scripts = ['http://code.jquery.com/jquery-1.4.3.min', '/socket.io/socket.io', '/default']

  h1 @title
  div id: 'log'
  form ->
    input id: 'box'
    button id: 'say', -> 'Say'
