get '/': ->
  @foo = 'ha'
  render 'index', apply: 'roles'

postrender roles: ->
  $('.red').css 'color', '#f00'

view index: ->
  h1 class: 'red', -> @foo

layout ->
  html ->
    head ->
    body -> @content
