require('./src/zappa') ->
  @enable 'default layout'
  
  @set views: __dirname + '/tests/views'

  @get '/': ->
    @render 'index'
  
  @view index: ->
    @title = 'shaboo'
    p 'inline view'
    
  @view layoute: ->
    doctype 5
    html ->
      head ->
        title 'inline layout'
      body @body