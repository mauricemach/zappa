zappa = require('./support/tester') require('../src/zappa')

module.exports =
  client: ->
    t = zappa ->
      client '/index.js': ->
        get '#/': -> alert 'hi'
    headers = 'Content-Type': 'application/javascript'
    body = ';zappa.run(function () {\n            return get({\n              \'#/\': function() {\n                return alert(\'hi\');\n              }\n            });\n          });'
    t.response {url: '/index.js'}, {headers, body}

  coffee: ->
    t = zappa ->
      coffee '/coffee.js': ->
        alert 'hi'
    headers = 'Content-Type': 'application/javascript'
    body = ';var __slice = Array.prototype.slice;var __hasProp = Object.prototype.hasOwnProperty;var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };var __extends = function(child, parent) {  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }  function ctor() { this.constructor = child; }  ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype;  return child; };var __indexOf = Array.prototype.indexOf || function(item) {  for (var i = 0, l = this.length; i < l; i++) {    if (this[i] === item) return i;  } return -1; };(function () {\n            return alert(\'hi\');\n          })();'
    t.response {url: '/coffee.js'}, {headers, body}
    
  js: ->
    t = zappa ->
      js '/js.js': '''
        alert('hi');
      '''
    headers = 'Content-Type': 'application/javascript'
    body = "alert('hi');"
    t.response {url: '/js.js'}, {headers, body}
    
  css: ->
    t = zappa ->
      css '/index.css': '''
        font-family: sans-serif;
      '''
    headers = 'Content-Type': 'text/css'
    body = 'font-family: sans-serif;'
    t.response {url: '/index.css'}, {headers, body}

  stylus: ->
    t = zappa ->
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

  jquery: ->
    t = zappa ->
      enable 'serve jquery'
    status = 200
    headers =
      'Content-Type': 'application/javascript'
      'Content-Length': '92334'
    t.response {url: '/zappa/jquery.js'}, {status, headers}

  sammy: ->
    t = zappa ->
      enable 'serve sammy'
    status = 200
    headers =
      'Content-Type': 'application/javascript'
      'Content-Length': '16854'
    t.response {url: '/zappa/sammy.js'}, {status, headers}

  zappa: ->
    t = zappa ->
      enable 'serve zappa'
    status = 200
    headers =
      'Content-Type': 'application/javascript'
      'Content-Length': '6864'
    t.response {url: '/zappa/zappa.js'}, {status, headers}

  'zappa (automatic)': ->
    t = zappa ->
      client '/index.js': ->
    status = 200
    headers =
      'Content-Type': 'application/javascript'
      'Content-Length': '6864'
    t.response {url: '/zappa/zappa.js'}, {status, headers}