get '/': -> render 'default'

get '/counter': -> "# of messages so far: #{app.counter}"

at connection: ->
  app.counter ?= 0
  puts "Connected: #{id}"
  broadcast 'connected', id: id

at disconnection: ->
  puts "Disconnected: #{id}"

msg said: ->
  puts "#{id} said: #{@text}"
  app.counter++
  send 'said', id: id, text: @text
  broadcast 'said', id: id, text: @text

client ->
  $(document).ready ->
    socket = new io.Socket 'localhost', {transports: ['websocket', 'xhr-multipart', 'xhr-polling', 'htmlfile', 'flashsocket']}

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
  @scripts = ['http://code.jquery.com/jquery-1.4.3.min', 'http://cdn.socket.io/stable/socket.io', 'default']

  h1 @title
  div id: 'log'
  form ->
    input id: 'box'
    button id: 'say', -> 'Say'
