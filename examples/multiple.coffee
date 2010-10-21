shared_layout = ->
  doctype 5
  html ->
    head ->
      title (@title or 'No Title')
    body -> @content

shared_index = ->
  h1 (@title or 'No Title')


app 'blog'

get '/': ->
  @title = 'Blog!'
  render 'index'

layout shared_layout
view index: shared_index


app 'chat'

port 8001

get '/': ->
  render 'index'

layout shared_layout
view index: shared_index
