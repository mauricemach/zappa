def sleep: (secs, cb) ->
  setTimeout cb, secs * 1000

get '/async/:foo': ->
  @foo += '?'
  sleep 5, =>
    @foo += '!'
    render 'index'

get '/:foo': ->
  @foo += '!'
  render 'index'

view index: ->
  p @foo

layout ->
  doctype 5
  html ->
    head ->
      title @foo
    body @content
