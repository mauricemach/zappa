require('../src/zappa').run ->
  enable 'sammy', 'jquery'

  get '/': ->
    render 'index'

  client '/index.js': ->
    get '#/': ->
      console.log 'home'
    
    get '#/foo': ->
      console.log 'bar'
  
  view index: ->
    h1 'client test'
    
  view layout: ->
    doctype 5
    html ->
      head ->
        title 'client test'
        script src: '/zappa/jquery.js'
        script src: '/zappa/zappa.js'
        script src: '/zappa/sammy.js'
        script src: '/index.js'
      body @body