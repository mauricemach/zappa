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
      get '/': -> response.render 'index', foo: 'bar', layout: no
    
    t.get '/', '<h2>CoffeeKup file template: bar</h2>'

  'Views (response.render, layout)': ->
    t = zappa ->
      get '/': -> response.render 'index', foo: 'bar'
    
    t.get '/', '<!DOCTYPE html><html><head><title>CoffeeKup file layout</title></head><body><h2>CoffeeKup file template: bar</h2></body></html>'
