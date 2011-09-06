zappa = require '../src/zappa'
port = 15600

@tests =
  inline: (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
      get '/': ->
        @foo = 'bar'
        render 'index', layout: no

      view index: -> h2 "CoffeeKup inline template: #{@foo}"
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<h2>CoffeeKup inline template: bar</h2>'

  'inline + inline layout': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
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

    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<!DOCTYPE html><html><head><title>CoffeeKup inline layout</title></head><body><h2>CoffeeKup inline template: bar</h2></body></html>'

  file: (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
      get '/': ->
        @foo = 'bar'
        render 'index', layout: no
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<h2>CoffeeKup file template: bar</h2>'

  'file + file layout': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
      get '/': ->
        @foo = 'bar'
        render 'index'
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<!DOCTYPE html><html><head><title>CoffeeKup file layout</title></head><body><h2>CoffeeKup file template: bar</h2></body></html>'

  'response.render, file': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
      get '/': ->
        response.render 'index', foo: 'bar', layout: no
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<h2>CoffeeKup file template: bar</h2>'

  'response.render, file + file layout': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
      get '/': ->
        response.render 'index', foo: 'bar'
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<!DOCTYPE html><html><head><title>CoffeeKup file layout</title></head><body><h2>CoffeeKup file template: bar</h2></body></html>'

  'eco, inline': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
      set 'view engine': 'eco'
      
      get '/': ->
        @foo = 'bar'
        render 'index', layout: no

      view index: "<h2>Eco inline template: <%= @params.foo %></h2>"
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<h2>Eco inline template: bar</h2>'

  'eco, inline + inline layout': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
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
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<!DOCTYPE html>\n<html>\n  <head>\n    <title>Eco inline layout</title>\n  </head>\n  <body><h2>Eco inline template: bar</h2></body>\n</html>'

  'eco, file': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
      set 'view engine': 'eco'
      
      get '/': ->
        @foo = 'bar'
        render 'index', layout: no
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<h2>Eco file template: bar</h2>'

  'eco, file + file layout': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
      set 'view engine': 'eco'
      
      get '/': ->
        @foo = 'bar'
        render 'index'
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<!DOCTYPE html>\n<html>\n  <head>\n    <title>Eco file layout</title>\n  </head>\n  <body><h2>Eco file template: bar</h2></body>\n</html>'

  'eco, zappa adapter, inline + inline layout': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
      set 'view engine': 'eco'
      app.register '.eco', zappa.adapter('eco')
      
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
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<!DOCTYPE html>\n<html>\n  <head>\n    <title>Eco inline layout</title>\n  </head>\n  <body><h2>Eco inline template: bar</h2></body>\n</html>'

  'jade, inline': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
      set 'view engine': 'jade'
      
      get '/': ->
        @foo = 'bar'
        render 'index', layout: no

      view index: "h2= 'Jade inline template: ' + params.foo"
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<h2>Jade inline template: bar</h2>'

  'jade, inline + inline layout': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
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
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<!DOCTYPE html><html><head><title>Jade inline layout</title></head><body><h2>Jade inline template: bar</h2></body></html>'

  'jade, file': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
      set 'view engine': 'jade'
      
      get '/': ->
        @foo = 'bar'
        render 'index', layout: no
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<h2>Jade file template: bar</h2>'

  'jade, file + file layout': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
      set 'view engine': 'jade'
      
      get '/': ->
        @foo = 'bar'
        render 'index'
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<!DOCTYPE html><html><head><title>Jade file layout</title></head><body><h2>Jade file template: bar</h2></body></html>'

  'jade, zappa adapter, inline + inline layout': (t) ->
    t.expect 1
    t.wait 3000
    
    zapp = zappa port++, ->
      set 'view engine': 'jade'
      app.register '.jade', zappa.adapter('jade')
      
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
    
    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<!DOCTYPE html><html><head><title>Jade inline layout</title></head><body><h2>Jade inline template: bar</h2></body></html>'