zappa = require('./support/tester') require('../src/zappa')

module.exports =
  'Views (inline)': ->
    t = zappa ->
      get '/': ->
        @foo = 'bar'
        render 'index', layout: no

      view index: -> h2 "CoffeeKup inline template: #{@foo}"
    
    t.get '/', '<h2>CoffeeKup inline template: bar</h2>'

  'Views (inline, inline layout)': ->
    t = zappa ->
      get '/': ->
        @foo = 'bar'
        render 'index'

      view index: -> h2 "CoffeeKup inline template: #{@foo}"

      view layout: ->
        doctype 5
        html ->
          head ->
            title 'CoffeeKup inline layout'
          body @body
    
    t.get '/', '<!DOCTYPE html><html><head><title>CoffeeKup inline layout</title></head><body><h2>CoffeeKup inline template: bar</h2></body></html>'

  'Views (file)': ->
    t = zappa ->
      get '/': ->
        @foo = 'bar'
        render 'index', layout: no
    
    t.get '/', '<h2>CoffeeKup file template: bar</h2>'

  'Views (file, file layout)': ->
    t = zappa ->
      get '/': ->
        @foo = 'bar'
        render 'index'
    
    t.get '/', '<!DOCTYPE html><html><head><title>CoffeeKup file layout</title></head><body><h2>CoffeeKup file template: bar</h2></body></html>'

  'Views (response.render)': ->
    t = zappa ->
      get '/': ->
        response.render 'index', foo: 'bar', layout: no
    
    t.get '/', '<h2>CoffeeKup file template: bar</h2>'

  'Views (response.render, layout)': ->
    t = zappa ->
      get '/': ->
        response.render 'index', foo: 'bar'
    
    t.get '/', '<!DOCTYPE html><html><head><title>CoffeeKup file layout</title></head><body><h2>CoffeeKup file template: bar</h2></body></html>'

  'Views (eco, inline)': ->
    t = zappa ->
      set 'view engine': 'eco'
      
      get '/': ->
        @foo = 'bar'
        render 'index', layout: no

      view index: "<h2>Eco inline template: <%= @params.foo %></h2>"
    
    t.get '/', '<h2>Eco inline template: bar</h2>'

  'Views (eco, inline, inline layout)': ->
    t = zappa ->
      set 'view engine': 'eco'
      
      get '/': ->
        @foo = 'bar'
        render 'index'

      view index: "<h2>Eco inline template: <%= @params.foo %></h2>"

      view layout: '''
        <!DOCTYPE html>
        <html>
          <head>
            <title>Eco inline layout</title>
          </head>
          <body><%- @body %></body>
        </html>
      '''

    t.get '/', '<!DOCTYPE html>\n<html>\n  <head>\n    <title>Eco inline layout</title>\n  </head>\n  <body><h2>Eco inline template: bar</h2></body>\n</html>'


  'Views (eco, file)': ->
    t = zappa ->
      set 'view engine': 'eco'
      
      get '/': ->
        @foo = 'bar'
        render 'index', layout: no
    
    t.get '/', '<h2>Eco file template: bar</h2>'

  'Views (eco, file, file layout)': ->
    t = zappa ->
      set 'view engine': 'eco'
      
      get '/': ->
        @foo = 'bar'
        render 'index'
    
    t.get '/', '<!DOCTYPE html>\n<html>\n  <head>\n    <title>Eco file layout</title>\n  </head>\n  <body><h2>Eco file template: bar</h2></body>\n</html>'

  'Views (eco, zappa adapter, inline, inline layout)': ->
    t = zappa ->
      set 'view engine': 'eco'
      app.register '.eco', require('../src/zappa').adapter('eco')
      
      get '/': ->
        @foo = 'bar'
        render 'index'

      view index: "<h2>Eco inline template: <%= @foo %></h2>"

      view layout: '''
        <!DOCTYPE html>
        <html>
          <head>
            <title>Eco inline layout</title>
          </head>
          <body><%- @body %></body>
        </html>
      '''

  'Views (jade, inline)': ->
    t = zappa ->
      set 'view engine': 'jade'
      
      get '/': ->
        @foo = 'bar'
        render 'index', layout: no

      view index: "h2= 'Jade inline template: ' + params.foo"
    
    t.get '/', '<h2>Jade inline template: bar</h2>'

  'Views (jade, inline, inline layout)': ->
    t = zappa ->
      set 'view engine': 'jade'
      
      get '/': ->
        @foo = 'bar'
        render 'index'

      view index: "h2= 'Jade inline template: ' + params.foo"

      view layout: '''
        !!! 5
        html
          head
            title Jade inline layout
          body!= body
      '''

    t.get '/', '<!DOCTYPE html><html><head><title>Jade inline layout</title></head><body><h2>Jade inline template: bar</h2></body></html>'


  'Views (jade, file)': ->
    t = zappa ->
      set 'view engine': 'jade'
      
      get '/': ->
        @foo = 'bar'
        render 'index', layout: no
    
    t.get '/', '<h2>Jade file template: bar</h2>'

  'Views (jade, file, file layout)': ->
    t = zappa ->
      set 'view engine': 'jade'
      
      get '/': ->
        @foo = 'bar'
        render 'index'
    
    t.get '/', '<!DOCTYPE html><html><head><title>Jade file layout</title></head><body><h2>Jade file template: bar</h2></body></html>'

  'Views (jade, zappa adapter, inline, inline layout)': ->
    t = zappa ->
      set 'view engine': 'jade'
      app.register '.jade', require('../src/zappa').adapter('jade')
      
      get '/': ->
        @foo = 'bar'
        render 'index'

      view index: "h2= 'Jade inline template: ' + foo"

      view layout: '''
        !!! 5
        html
          head
            title Jade inline layout
          body!= body
      '''