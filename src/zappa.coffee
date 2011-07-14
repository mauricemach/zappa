# **Zappa** is a [CoffeeScript](http://coffeescript.org) DSL-ish interface for building web apps on the
# [node.js](http://nodejs.org) runtime, integrating [express](http://expressjs.com), [socket.io](http://socket.io)
# and other best-of-breed libraries.

log = console.log
fs = require 'fs'

@version = '0.2.0beta'

# CoffeeScript-generated JavaScript may contain anyone of these; when we "rewrite"
# a function (see below) though, it loses access to its parent scope, and consequently to
# any helpers it might need. So we need to reintroduce these helpers manually inside any
# "rewritten" function.
coffeescript_helpers = """
  var __slice = Array.prototype.slice;
  var __hasProp = Object.prototype.hasOwnProperty;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  var __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype;
    return child; };
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    } return -1; };
""".replace /\n/g, ''

# "Rewrites" a function so that it accepts the value of @/this ("context")
# and local variables as parameters.
# The names of local variables to be "extracted" have to be provided beforehand.
# The function will lose access to its parent scope in the process.
rewrite_function = (func, locals_names) ->
  code = String(func)
  code = "function () {#{code}}" unless code.indexOf 'function' is 0
  code = "#{coffeescript_helpers}return (#{code}).apply(context, args);"
  for name in locals_names
    code = "var #{name} = locals.#{name};" + code
  new Function('context', 'locals', 'args', code)

# Takes in a function and builds express/socket.io apps based on the rules contained in it.
@app = (root_function) ->
  # Names of local variables that we have to know beforehand, to use with `rewrite_function`.
  # Helpers and defs will be known after we execute the user-provided `root_function`.
  # TODO: __filename and __dirname won't work this way. Find another solution.
  globals = ['global', 'process', 'console', 'require', '__filename', '__dirname',
    'module', 'setTimeout', 'clearTimeout', 'setInterval', 'clearInterval']  
  # TODO: using?, route?, postrender?, enable, disable, settings, error
  root_locals_names = ['express', 'io', 'app', 'get', 'post', 'put', 'del', 'at',
    'helper', 'def', 'view', 'set', 'use', 'configure', 'include', 'client', 'coffee', 'js', 'css',
    'enable', 'disable']
  # TODO: app? (something shared with ws_handlers), app.clients?
  http_locals_names = ['response', 'request', 'next', 'params', 'send', 'render', 'redirect']
  # TODO: emit?, broadcast, render?, app? (shared between http-ws, persistent)
  ws_locals_names = ['socket', 'id', 'params', 'client']
  helpers_names = []
  defs_names = []

  # Storage for the functions provided by the user.
  routes = []
  ws_handlers = {}
  helpers = {}
  defs = {}
  views = {}
  
  # Builds the applications's root scope.
  express = require 'express'
  socketio = require 'socket.io'

  # Monkeypatch express to support inline templates. Such is life.
  express.View.prototype.__defineGetter__ 'exists', ->
    return true if views[@view]?
    try
      fs.statSync(@path)
      return true
    catch err
      return false
  express.View.prototype.__defineGetter__ 'contents', ->
    return views[@view] if views[@view]?
    fs.readFileSync @path, 'utf8'

  app = express.createServer()
  io = socketio.listen(app)
  io.set 'log level', 1

  root_context = {}
  root_locals = {express, io, app}
  root_locals[g] = eval(g) for g in globals

  for verb in ['get', 'post', 'put', 'del']
    do (verb) ->
      root_locals[verb] = ->
        if typeof arguments[0] isnt 'object'
          routes.push verb: verb, path: arguments[0], handler: arguments[1]
        else
          for k, v of arguments[0]
            routes.push verb: verb, path: k, handler: v

  root_locals.client = (obj) ->
    app.enable 'zappa serve client'
    for k, v of obj
      js = ";zappa.run(#{v});"
      routes.push verb: 'get', path: k, handler: js, contentType: 'js'

  root_locals.coffee = (obj) ->
    for k, v of obj
      js = ";#{coffeescript_helpers}(#{v})();"
      routes.push verb: 'get', path: k, handler: js, contentType: 'js'

  root_locals.js = (obj) ->
    for k, v of obj
      js = String(v)
      routes.push verb: 'get', path: k, handler: js, contentType: 'js'

  root_locals.css = (obj) ->
    for k, v of obj
      css = String(v)
      routes.push verb: 'get', path: k, handler: css, contentType: 'css'

  root_locals.helper = (obj) ->
    for k, v of obj
      helpers_names.push k
      helpers[k] = v

  root_locals.def = (obj) ->
    for k, v of obj
      defs_names.push k
      defs[k] = v

  root_locals.at = (obj) ->
    for k, v of obj
      ws_handlers[k] = v

  root_locals.view = (obj) ->
    for k, v of obj
      views[k] = v

  root_locals.set = (obj) ->
    for k, v of obj
      app.set k, v

  root_locals.use = (obj) ->
    app.use.apply app, arguments

  root_locals.configure = ->
    app.configure.apply app, arguments

  root_locals.include = (name) ->
    sub = require name
    rewritten_sub = rewrite_function(sub, root_locals_names.concat(globals))
    rewritten_sub(root_context, root_locals)

  # Executes the (rewriten) end-user function and learns how the app should be structured.
  rewritten_root = rewrite_function(root_function, root_locals_names.concat(globals))
  rewritten_root(root_context, root_locals)

  # Implements the application according to the specification.

  for k, v of helpers
    helpers[k] = rewrite_function(v, http_locals_names.concat(helpers_names).concat(defs_names).concat(globals))

  for k, v of ws_handlers
    ws_handlers[k] = rewrite_function(v, ws_locals_names.concat(helpers_names).concat(defs_names).concat(globals))

  if app.settings['zappa serve client']
    app.get '/zappa/zappa.js', (req, res) ->
      res.contentType 'js'
      res.send ";#{coffeescript_helpers}(#{zappa_client_js})();"

  if app.settings['zappa serve jquery']
    app.get '/zappa/jquery.js', (req, res) ->
      res.contentType 'js'
      fs.readFile 'node_modules/jquery/dist/node-jquery.min.js', (err, data) ->
        res.send data.toString()

  if app.settings['zappa serve sammy']
    app.get '/zappa/sammy.js', (req, res) ->
      res.contentType 'js'
      fs.readFile 'sammy.min.js', (err, data) ->
        res.send data.toString()

  # Implements the http server with express.
  for r in routes
    do (r) ->
      if typeof r.handler is 'string'
        app[r.verb] r.path, (req, res) ->
          res.contentType r.contentType if r.contentType?
          res.send r.handler
      else
        rewritten_handler = rewrite_function(r.handler,
          http_locals_names.concat(helpers_names).concat(defs_names).concat(globals))

        context = null
        locals = {}
        locals[g] = eval(g) for g in globals

        for name, def of defs
          locals[name] = def

        for name, helper of helpers
          locals[name] = ->
            helper(context, locals, arguments)
            
        app[r.verb] r.path, (req, res, next) ->
          context = {}
          context[k] = v for k, v of req.query
          context[k] = v for k, v of req.params
          context[k] = v for k, v of req.body
          locals.params = context
          locals.request = req
          locals.response = res
          locals.next = next
          locals.send = -> res.send.apply res, arguments
          locals.render = ->
            args = []
            args.push a for a in arguments
            args[1] ?= {}
            args[1][k] = v for k, v of context
            res.render.apply res, args
          locals.redirect = -> res.redirect.apply res, arguments
          result = rewritten_handler(context, locals)
          res.contentType(r.contentType) if r.contentType?
          if typeof result is 'string' then res.send result
          else return result

  # Implements the websockets server with socket.io.
  io.sockets.on 'connection', (socket) ->
    context = {}
    locals = {socket, id: socket.id, client: {}}
    locals[g] = eval(g) for g in globals

    for name, def of defs
      locals[name] = def

    for name, helper of helpers
      locals[name] = ->
        helper(context, locals, arguments)
    
    ws_handlers.connection(context, locals) if ws_handlers.connection?

    socket.on 'disconnect', ->
      context = {}
      ws_handlers.disconnect(context, locals) if ws_handlers.disconnect?

    for name, h of ws_handlers
      if name isnt 'connection' and name isnt 'disconnect'
        socket.on name, (data) ->
          context = {}
          locals.params = context
          for k, v of data
            context[k] = v
          h(context, locals)

  {app, io}

# Takes a function and runs it as a zappa app. Optionally accepts a number for port,
# and/or a string for hostname (any order).
# Returns an object where `app` is the express server and `io` is the socket.io handle.
# Ex.:
#     require('zappa').run -> get '/': 'hi'
#     require('zappa').run 80, -> get '/': 'hi'
#     require('zappa').run 'domain.com', 80, -> get '/': 'hi'
@run = ->
  host = null
  port = 5678
  root_function = null

  for a in arguments
    switch typeof a
      when 'string' then host = a
      when 'number' then port = a
      when 'function' then root_function = a

  zapp = @app(root_function)

  if host? then zapp.app.listen port, host
  else zapp.app.listen port

  zapp

# Client-side zappa.
zappa_client = ->
  zappa = window.zappa = {}
  zappa.version = null

  coffeescript_helpers = null
  rewrite_function = null

  zappa.run = (root_function) ->
    root_locals_names = ['def', 'helper', 'get', 'socket', 'connect', 'at']
    sammy_locals_names = []
    ws_locals_names = ['socket', 'id', 'params', 'client']
    helpers_names = []
    defs_names = []

    # Storage for the functions provided by the user.
    routes = []
    ws_handlers = {}
    helpers = {}
    defs = {}

    socket = null
    app = Sammy() if Sammy?

    root_context = {}
    root_locals = {}

    root_locals.get = ->
      if typeof arguments[0] isnt 'object'
        routes.push({path: arguments[0], handler: arguments[1]})
      else
        for k, v of arguments[0]
          routes.push({path: k, handler: v})

    root_locals.helper = (obj) ->
      for k, v of obj
        helpers_names.push k
        helpers[k] = v

    root_locals.def = (obj) ->
      for k, v of obj
        defs_names.push k
        defs[k] = v

    root_locals.at = (obj) ->
      for k, v of obj
        ws_handlers[k] = v

    root_locals.connect = ->
      socket = io.connect.apply io, arguments

    # Executes the (rewriten) end-user function and learns how the app should be structured.
    rewritten_root = rewrite_function(root_function, root_locals_names)
    rewritten_root(root_context, root_locals)

    # Implements the application according to the specification.

    for k, v of helpers
      helpers[k] = rewrite_function(v, http_locals_names.concat(helpers_names).concat(defs_names))

    for k, v of ws_handlers
      ws_handlers[k] = rewrite_function(v, ws_locals_names.concat(helpers_names).concat(defs_names))

    for r in routes
      do (r) ->
        rewritten_handler = rewrite_function(r.handler,
          sammy_locals_names.concat(helpers_names).concat(defs_names))

        context = null
        locals = {}

        for name, def of defs
          locals[name] = def

        for name, helper of helpers
          locals[name] = ->
            helper(context, locals, arguments)

        app.get r.path, ->
          context = {}
          locals.params = context
          rewritten_handler(context, locals)

    # Implements the websockets client with socket.io.
    if socket?
      context = {}
      locals = {socket}

      for name, def of defs
        locals[name] = def

      for name, helper of helpers
        locals[name] = ->
          helper(context, locals, arguments)

      for name, h of ws_handlers
        socket.on name, (data) ->
          context = {}
          locals.params = context
          for k, v of data
            context[k] = v
          h(context, locals)

    $(-> app.run '#/')

zappa_client_js = String(zappa_client)
  .replace('version = null;', "version = '#{@version}';")
  .replace('coffeescript_helpers = null;', "var coffeescript_helpers = '#{coffeescript_helpers}';")
  .replace('rewrite_function = null;', "var rewrite_function = #{rewrite_function};")
  .replace /(\n)/g, ''
