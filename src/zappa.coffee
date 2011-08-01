# **Zappa** is a [CoffeeScript](http://coffeescript.org) DSL-ish interface for building web apps on the
# [node.js](http://nodejs.org) runtime, integrating [express](http://expressjs.com), [socket.io](http://socket.io)
# and other best-of-breed libraries.

zappa = version: '0.2.0beta'

log = console.log
fs = require 'fs'
path = require 'path'
express = require 'express'
socketio = require 'socket.io'
jsdom = require 'jsdom'
jquery = fs.readFileSync(__dirname + '/../vendor/jquery-1.6.2.min.js').toString()
sammy = fs.readFileSync(__dirname + '/../vendor/sammy-latest.min.js').toString()

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

# The stringified zappa client.
client = require('./client').build(zappa.version, coffeescript_helpers, rewrite_function)

# Takes in a function and builds express/socket.io apps based on the rules contained in it.
# The optional data object allows passing variables from the outside to the root scope.
zappa.app = ->
  data = null
  root_function = null
  
  for a in arguments
    switch typeof a
      when 'function' then root_function = a
      when 'object' then data = a

  # Names of local variables that we have to know beforehand, to use with `rewrite_function`.
  # Helpers and defs will be known after we execute the user-provided `root_function`.

  # The last four (`require`, `module`, `__filename` and `__dirname`) are not actually real globals,
  # but locals to each module.
  globals_names = ['global', 'process', 'console', 'setTimeout', 'clearTimeout', 'setInterval', 'clearInterval',
    'require', 'module', '__filename', '__dirname']

  # TODO: route?, error
  root_names = ['zappa', 'express', 'app', 'io', 'requiring', 'get', 'post', 'put', 'del', 'at',
    'helper', 'def', 'view', 'set', 'use', 'configure', 'include', 'shared', 'client', 'coffee', 'js', 'css',
    'enable', 'disable', 'settings', 'postrender']

  # TODO: session, postrender, app data, clients list
  http_names = ['app', 'settings', 'response', 'request', 'next', 'params', 'send', 'render', 'redirect']

  # TODO: app data, clients list
  ws_names = ['app', 'io', 'settings', 'socket', 'id', 'params', 'client', 'emit', 'broadcast']
  
  postrender_names = ['window', '$']
  
  externals_names = []
  externals_names.push k for k, v of data
  
  helpers_names = []
  defs_names = []

  # Storage for the user-provided handlers.
  routes = []
  ws_handlers = {}
  helpers = {}
  defs = {}
  views = {}
  postrenders = {}
  
  # Monkeypatch express to support inline templates. Such is life.
  # TODO: this doesn't work for multiple apps.
  express.View.prototype.__defineGetter__ 'exists', ->
    return true if views[@view]?
    return true if views[path.basename(@view)]?
    try
      fs.statSync(@path)
      return true
    catch err
      return false
      
  express.View.prototype.__defineGetter__ 'contents', ->
    return views[@view] if views[@view]?
    return views[path.basename(@view)] if views[path.basename(@view)]?
    fs.readFileSync @path, 'utf8'
  
  app = express.createServer()
  io = socketio.listen(app)

  # Zappa's default settings.
  app.set 'view engine', 'coffee'
  app.register '.coffee', zappa.adapter require('coffeekup').adapters.express,
    blacklist: ['format', 'autoescape', 'locals', 'hardcode', 'cache']

  # Builds the applications's root scope.

  root_context = {}
  root_locals = {zappa, express, app, io}
  root_locals[k] = v for k, v of data
  root_locals[g] = eval(g) for g in globals_names
  
  # These "globals" are actually local to each module, so we get our values
  # from our parent module.
  root_locals.module = module.parent
  root_locals.__filename = module.parent.filename
  root_locals.__dirname = path.dirname(module.parent.filename)
  # TODO: Find out how to pass the correct `require` (the module's, not zappa's) to the app.
  # root_locals.require = ???
  # Meanwhile, adding the app's root dir to the front of the lookup stack.
  require.paths.unshift root_locals.__dirname
  
  for verb in ['get', 'post', 'put', 'del']
    do (verb) ->
      root_locals[verb] = ->
        if typeof arguments[0] isnt 'object'
          routes.push verb: verb, path: arguments[0], handler: arguments[1]
        else
          for k, v of arguments[0]
            routes.push verb: verb, path: k, handler: v

  root_locals.client = (obj) ->
    app.enable 'serve zappa'
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

  root_locals.postrender = (obj) ->
    for k, v of obj
      postrenders[k] = v

  root_locals.at = (obj) ->
    for k, v of obj
      ws_handlers[k] = v

  root_locals.view = (obj) ->
    for k, v of obj
      views[k] = v

  root_locals.set = (obj) ->
    for k, v of obj
      app.set k, v
      
  root_locals.enable = ->
    app.enable i for i in arguments

  root_locals.disable = ->
    app.disable i for i in arguments

  root_locals.use = ->
    wrappers =
      static: (path = root_locals.__dirname + '/public') -> express.static(path)

    use = (name, arg = null) ->
      if wrappers[name]
        app.use wrappers[name](arg)
      else if typeof express[name] is 'function'
        app.use express[name](arg)
     
    for a in arguments
      switch typeof a
        when 'function' then app.use a
        when 'string' then use a
        when 'object' then use k, v for k, v of a
    
  root_locals.requiring = ->
    pairs = {}
    for a in arguments
      pairs[a] = require a
    root_locals.def pairs

  root_locals.configure = (p) ->
    if typeof p is 'function' then app.configure p
    else app.configure k, v for k, v of p
    
  root_locals.settings = app.settings

  root_locals.shared = (obj) ->
    app.enable 'serve zappa'
    for k, v of obj
      js = ";zappa.run(#{v});"
      routes.push verb: 'get', path: k, handler: js, contentType: 'js'

      rewritten_shared = rewrite_function(v, root_names.concat(globals_names).concat(externals_names))
      rewritten_shared(root_context, root_locals)

  root_locals.include = (name) ->
    sub = root_locals.require name
    rewritten_sub = rewrite_function(sub.include, root_names.concat(globals_names).concat(externals_names))

    include_locals = {}
    include_locals[k] = v for k, v of root_locals

    include_module = require.cache[require.resolve(name)]
    
    # These "globals" are actually local to each module, so we get our values
    # from the required module.
    include_locals.module = include_module
    include_locals.__filename = include_module.filename
    include_locals.__dirname = path.dirname(include_module.filename)
    # TODO: Find out how to pass the correct `require` (the module's, not zappa's) to the include.
    # include_locals.require = ???

    rewritten_sub(root_context, include_locals)

  # Executes the (rewriten) end-user function and learns how the app should be structured.
  rewritten_root = rewrite_function(root_function, root_names.concat(globals_names).concat(externals_names))
  rewritten_root(root_context, root_locals)

  # Implements the application according to the specification.

  for k, v of helpers
    helpers[k] = rewrite_function(v, http_names.concat(helpers_names).concat(defs_names).concat(globals_names))

  for k, v of ws_handlers
    ws_handlers[k] = rewrite_function(v, ws_names.concat(helpers_names).concat(defs_names).concat(globals_names))

  for k, v of postrenders
    postrenders[k] = rewrite_function(v, postrender_names.concat(helpers_names).concat(defs_names).concat(globals_names))

  if app.settings['serve zappa']
    app.get '/zappa/zappa.js', (req, res) ->
      res.contentType 'js'
      res.send ";#{coffeescript_helpers}(#{client})();"

  if app.settings['serve jquery']
    app.get '/zappa/jquery.js', (req, res) ->
      res.contentType 'js'
      res.send jquery

  if app.settings['serve sammy']
    app.get '/zappa/sammy.js', (req, res) ->
      res.contentType 'js'
      ren.send sammy

  if app.settings['default layout']
    views.layout = ->
      doctype 5
      html ->
        head ->
          title @title if @title
          if @scripts
            for s in @scripts
              script src: s + '.js'
          script(src: @script + '.js') if @script
          if @stylesheets
            for s in @stylesheets
              link rel: 'stylesheet', href: s + '.css'
          link(rel: 'stylesheet', href: @stylesheet + '.css') if @stylesheet
          style @style if @style
        body @body

  # Implements the http server with express.
  for r in routes
    do (r) ->
      if typeof r.handler is 'string'
        app[r.verb] r.path, (req, res) ->
          res.contentType r.contentType if r.contentType?
          res.send r.handler
      else
        rewritten_handler = rewrite_function(r.handler,
          http_names.concat(helpers_names).concat(defs_names).concat(globals_names))

        context = null
        locals = {app, settings: app.settings}
        
        # TODO: fix pseudo-globals here too.
        locals[g] = eval(g) for g in globals_names

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
          locals.redirect = -> res.redirect.apply res, arguments

          locals.render = (args...) ->
            # Make sure the second arg is an object.
            args[1] ?= {}
            args.splice 1, 0, {} if typeof args[1] is 'function'
            
            # Send request input vars to template as `params`.
            args[1].params ?= locals.params

            if args[1].postrender?
              # Apply postrender before sending response.
              res.render args[0], args[1], (err, str) ->
                jsdom.env html: str, src: [jquery], done: (err, window) ->
                  locals.window = window
                  locals.$ = window.$

                  rendered = postrenders[args[1].postrender](context, locals)

                  doctype = (window.document.doctype or '') + "\n"
                  res.send doctype + window.document.documentElement.outerHTML
            else
              # Just forward params to express.
              res.render.apply res, args

          result = rewritten_handler(context, locals)
          
          res.contentType(r.contentType) if r.contentType?
          if typeof result is 'string' then res.send result
          else return result

  # Implements the websockets server with socket.io.
  io.sockets.on 'connection', (socket) ->
    context = {}
    locals =
      app: app
      io: io
      settings: app.settings
      socket: socket
      id: socket.id
      client: {}
      emit: -> socket.emit.apply socket, arguments
      broadcast: -> socket.broadcast.emit.apply socket.broadcast, arguments

    # TODO: fix pseudo-globals here too.
    locals[g] = eval(g) for g in globals_names

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
      do (name, h) ->
        if name isnt 'connection' and name isnt 'disconnect'
          socket.on name, (data) ->
            context = {}
            context[k] = v for k, v of data
            locals.params = context
            h(context, locals)

  {app, io}

# Takes a function and runs it as a zappa app. Optionally accepts a number for port,
# and/or a string for hostname (any order).
# Returns an object where `app` is the express server and `io` is the socket.io handle.
# Ex.:
#     require('zappa') -> get '/': 'hi'
#     require('zappa').run 80, -> get '/': 'hi'
#     require('zappa') -> 'domain.com', 80, -> get '/': 'hi'
zappa.run = ->
  host = null
  port = 3000
  root_function = null
  data = null

  for a in arguments
    switch typeof a
      when 'string' then host = a
      when 'number' then port = a
      when 'function' then root_function = a
      when 'object' then data = a

  zapp = zappa.app(data, root_function)
  app = zapp.app

  if host then app.listen port, host
  else app.listen port

  log 'Express server listening on port %d in %s mode',
    app.address().port, app.settings.env

  log "Zappa #{zappa.version} orchestrating the show"

  zapp

# Creates a zappa view adapter for templating engine `engine`. This adapter
# can be used with `app.register` and creates params "shortcuts".
# 
# Zappa, by default, automatically sends all request params to templates,
# but inside the `params` local.
#
# This adapter adds a "root local" for each of these params, *only* 
# if a local with the same name doesn't exist already, *and* the name is not
# in the optional blacklist.
#
# The blacklist is useful to prevent request params from triggering unset
# template engine options.
#
# If `engine` is a string, the adapter will use `require(engine)`. Otherwise,
# it will assume the `engine` param is an object with a `compile` function.
zappa.adapter = (engine, options = {}) ->
  options.blacklist ?= []
  engine = require(engine) if typeof engine is 'string'
  compile: (template, data) ->
    template = engine.compile(template, data)
    (data) ->
      for k, v of data.params
        if typeof data[k] is 'undefined' and k not in options.blacklist
          data[k] = v
      template(data)

module.exports = zappa.run
module.exports.run = zappa.run
module.exports.app = zappa.app
module.exports.adapter = zappa.adapter
module.exports.version = zappa.version