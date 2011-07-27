zappa = require '../src/zappa'

zappa.run 8000, ->
  get '/': 'blog'

zappa.run 8001, ->
  get '/': 'chat'

zappa.run 8002, ->
  get '/': 'wiki'
