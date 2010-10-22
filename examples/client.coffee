get '/': ->
  render 'default'

client ->
  $(document).ready -> $('body').append "<p>default client</p>"

client named: ->
  $(document).ready -> $('body').append "<p>named client</p>"

client 'admin/namespaced': ->
  $(document).ready -> $('body').append "<p>namespaced client</p>"

style '''
  #default.css {border: 1px solid #00f}
'''

style named: '''
  #named.css {border: 1px solid #f00}
'''

style 'admin/namespaced': '''
  #namespaced.css {border: 1px solid #0f0}
'''

view ->
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
