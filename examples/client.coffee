require('../src/zappa') ->
  @enable 'default layout', 'serve jquery'
  
  @get '/': -> @render 'index'

  @coffee '/index.js': ->
    $(document).ready -> $('body').append "<p>@coffee</p>"

  @css '/index.css': '''
    #css {display: block !important;}
  '''

  @view index: ->
    @title = 'Client'
    @scripts = ['/zappa/jquery', '/index']
    @stylesheets = ['/index']

    h1 @title
    p '#css', style: 'display: none', '@css'