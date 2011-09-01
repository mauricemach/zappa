require('zappa') ->
  enable 'default layout'
  
  get '/': ->
    render 'index'

  client '/index.js': ->
    $(document).ready -> $('body').append "<p>default client</p>"

  css '/index.css': ''''
    #default.css {border: 1px solid #00f}
  '''

  view index: ->
    @title = 'Client'
    @scripts = ['http://code.jquery.com/jquery-1.4.3.min', 'default', 'named', 'admin/namespaced']
    @stylesheets = ['default', 'named', 'admin/namespaced']
    @style = '''
      .css {font-family: monospace}
    '''

    h1 @title
    p id: 'default', class: 'css', -> 'default stylesheet'
    p id: 'named', class: 'css', -> 'named stylesheet'
    p id: 'namespaced', class: 'css', -> 'namespaced stylesheet'
