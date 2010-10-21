get '/': -> render 'index'

get '/counter': -> "Total messages so far: #{app.counter}"

at connection: ->
  app.counter ?= 0
  puts "Connected: #{id}"
  puts inspect client.connection

at disconnection: ->
  puts "Disconnected: #{id}"

msg said: ->
  puts "#{id} said: #{@text}"
  app.counter++
  send 'said', id: id, text: @text
  broadcast 'said', id: id, text: @text

client index: ->
  $(document).ready ->
    socket = new io.Socket 'localhost'

    socket.on 'connect', ->
      $('#log').append '<p>Connected</p>'

    socket.on 'message', (raw_msg) ->
      msg = JSON.parse raw_msg
      $('#log').append "<p>#{msg.said.id}: #{msg.said.text}</p>" if msg.said

    socket.on 'disconnect', ->
      $('#log').append '<p>Disconnected</p>'

    socket.connect()
    $('#box').focus()

    $('form').submit ->
      socket.send JSON.stringify said: {text: $('#box').val()}
      $('#box').val('').focus()
      false

layout ->
  html ->
    head ->
      script src: 'http://code.jquery.com/jquery-1.4.3.min.js'
      script src: 'http://cdn.socket.io/stable/socket.io.js'
      script src: '/index.js'
    body -> @content

view index: ->
  h1 'Chat'
  div id: 'log'
  form ->
    input id: 'box'
    button id: 'say', -> 'Say'
