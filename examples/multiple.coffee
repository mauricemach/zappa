zappa = require '../src/zappa'

zappa 8000, ->
  @get '/': 'blog'

zappa 8001, ->
  @get '/': 'chat'

zappa 8002, ->
  @get '/': 'wiki'
