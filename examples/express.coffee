app = require('express').createServer()
app.get '/', (req, res) ->
  res.send 'foo'
app.listen()
console.log app.address()