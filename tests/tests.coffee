{Tester} = require('./tester')

module.exports =
  hello: ->
    t = new Tester ->
      get '/string': 'string'
      get '/return': -> 'return'
      get '/send': -> send 'send'
    
    t.get '/string', 'string'
    t.get '/return', 'return'
    t.get '/send', 'send'

  verbs: ->
    t = new Tester ->
      post '/': 'post'
      put '/': -> 'put'
      del '/': -> send 'del'
    
    t.response {method: 'post', url: '/'}, {body: 'post'}
    t.response {method: 'put', url: '/'}, {body: 'put'}
    t.response {method: 'delete', url: '/'}, {body: 'del'}

  redirect: ->
    t = new Tester ->
      get '/': -> redirect '/foo'
    
    t.response {url: '/'}, {status: 302, headers: {Location: /\/foo$/}}
    
  params: ->
    t = new Tester ->
      use 'bodyParser'
      get '/:foo': -> @foo + @ping
      post '/:foo': -> @foo + @ping + @zig
    
    t.get '/bar?ping=pong', 'barpong'
    headers = 'Content-Type': 'application/x-www-form-urlencoded'
    t.response {method: 'post', url: '/bar?ping=pong', data: 'zig=zag', headers}, {body: 'barpongzag'}
    
  static: ->
    t = new Tester ->
      use 'static'
    
    t.get '/foo.txt', 'bar'

  view: ->
    t = new Tester ->
      get '/': -> render 'index', layout: no
      view index: -> h1 'foo'
    
    t.get '/', '<h1>foo</h1>'

  'view (file)': ->
    t = new Tester ->
      get '/': -> render 'index', layout: no
    
    t.get '/', '<h2>CoffeeKup file template</h2>'

  'view (response.render)': ->
    t = new Tester ->
      get '/': -> response.render 'index', layout: no
    
    t.get '/', '<h2>CoffeeKup file template</h2>'
              
  'coffee and js': ->
    t = new Tester ->
      coffee '/coffee.js': ->
        alert 'hi'
      js '/js.js': '''
        alert('hi');
      '''
    headers = 'Content-Type': 'application/javascript'
    body = ';var __slice = Array.prototype.slice;var __hasProp = Object.prototype.hasOwnProperty;var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };var __extends = function(child, parent) {  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }  function ctor() { this.constructor = child; }  ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype;  return child; };var __indexOf = Array.prototype.indexOf || function(item) {  for (var i = 0, l = this.length; i < l; i++) {    if (this[i] === item) return i;  } return -1; };(function () {\n            return alert(\'hi\');\n          })();'
    t.response {url: '/coffee.js'}, {headers, body}
    body = "alert('hi');"
    t.response {url: '/js.js'}, {headers, body}
    
  css: ->
    t = new Tester ->
      css '/index.css': '''
        font-family: sans-serif;
      '''
    headers = 'Content-Type': 'text/css'
    body = 'font-family: sans-serif;'
    t.response {url: '/index.css'}, {headers, body}

  stylus: ->
    t = new Tester ->
      stylus '/index.css': '''
        border-radius()
          -webkit-border-radius arguments  
          -moz-border-radius arguments  
          border-radius arguments  

        body
          font 12px Helvetica, Arial, sans-serif  

        a.button
          border-radius 5px
      '''
    headers = 'Content-Type': 'text/css'
    body = '''
      body {
        font: 12px Helvetica, Arial, sans-serif;
      }
      a.button {
        -webkit-border-radius: 5px;
        -moz-border-radius: 5px;
        border-radius: 5px;
      }
      
    '''
    t.response {url: '/index.css'}, {headers, body}