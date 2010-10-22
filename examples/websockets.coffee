get '/': -> render 'index'

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

client index: ->
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

layout ->
  doctype 5
  html ->
    head ->
      title 'Nano Chat'
      script src: 'http://code.jquery.com/jquery-1.4.3.min.js'
      script src: 'http://cdn.socket.io/stable/socket.io.js'
      script src: '/index.js'
    body -> @content

view index: ->
  h1 'Nano Chat'
  div id: 'log'
  form ->
    input id: 'box'
    button id: 'say', -> 'Say'
