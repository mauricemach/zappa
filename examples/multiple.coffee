zappa = require '../src/zappa'

zappa.run 8000, ->
  get '/': 'blog'

zappa.run 8001, ->
  #app 'chat'
  get '/': 'chat'

zappa.run 8002, ->
  #app 'wiki'
  get '/': 'wiki'
