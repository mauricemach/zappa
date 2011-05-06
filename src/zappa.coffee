zappa = exports
express = require 'express'
fs = require 'fs'
puts = console.log
{inspect} = require 'sys'
coffee = null
jquery = null
io = null
coffeekup = null

class Zappa
  constructor: ->
    @context = {}
    @apps = {}
    @current_app = null

    @locals =
      app: (name) => @app name
      include: (path) => @include path
      require: require
      global: global
      process: process
      module: module

    for name in 'get|post|put|del|route|at|msg|client|using|def|helper|postrender|layout|view|style'.split '|'
      do (name) =>
        @locals[name] = =>
          @ensure_app 'default' unless @current_app?
          @current_app[name].apply @current_app, arguments

  app: (name) ->
    @ensure_app name
    @current_app = @apps[name]
  
  include: (file) ->
    @define_with @read_and_compile(file)
    puts "Included file \"#{file}\""

  define_with: (code) ->
    scoped(code)(@context, @locals)

  ensure_app: (name) ->
    @apps[name] = new App(name) unless @apps[name]?
    @current_app = @apps[name] unless @current_app?

  read_and_compile: (file) ->
    coffee = require 'coffee-script'
    code = @read file
    coffee.compile code
  
  read: (file) -> fs.readFileSync file, 'utf8'
  
  run_file: (file, options) ->
    @locals.__filename = require('path').join(process.cwd(), file)
    @locals.__dirname = process.cwd()
    @locals.module.filename = @locals.__filename
    code = if file.match /\.coffee$/ then @read_and_compile file else @read file
    @run code, options
  
  run: (code, options) ->
    options ?= {}

    @define_with code
    
    i = 0
    for k, a of @apps
      opts = {}
      if options.port
        opts.port = if options.port[i]? then options.port[i] else a.port + i
      else if i isnt 0
        opts.port = a.port + i

      opts.hostname = options.hostname if options.hostname

      a.start opts
      i++

class App
  constructor: (@name) ->
    @name ?= 'default'
    @port = 5678
    
    @http_server = express.createServer()
    if coffeekup?
      @http_server.register '.coffee', coffeekup
      @http_server.set 'view engine', 'coffee'
    @http_server.configure =>
      @http_server.use express.static("#{process.cwd()}/public")
      @http_server.use express.bodyParser()
      @http_server.use express.cookieParser()
      # TODO: Make the secret configurable.
      @http_server.use express.session(secret: 'hackme')

    # App-level vars, exposed to handlers as [app]."
    @vars = {}
    
    @defs = {}
    @helpers = {}
    @postrenders = {}
    @socket_handlers = {}
    @msg_handlers = {}

    @views = {}
    @layouts = {}
    @layouts.default = ->
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
        body @content
    
  start: (options) ->
    options ?= {}
    @port = options.port if options.port
    @hostname = options.hostname if options.hostname

    if io?
      @ws_server = io.listen @http_server, {log: ->}
      @ws_server.on 'connection', (client) =>
        @socket_handlers.connection?.execute client
        client.on 'disconnect', => @socket_handlers.disconnection?.execute client
        client.on 'message', (raw_msg) =>
          msg = parse_msg raw_msg
          @msg_handlers[msg.title]?.execute client, msg.params

    if @hostname? then @http_server.listen @port, @hostname
    else @http_server.listen @port
    
    puts "App \"#{@name}\" listening on #{if @hostname? then @hostname + ':' else '*:'}#{@port}..."
    @http_server

  get: -> @route 'get', arguments
  post: -> @route 'post', arguments
  put: -> @route 'put', arguments
  del: -> @route 'del', arguments
  route: (verb, args) ->
    if typeof args[0] isnt 'object'
      @register_route verb, args[0], args[1]
    else
      for k, v of args[0]
        @register_route verb, k, v

  register_route: (verb, path, response) ->
    if typeof response isnt 'function'
      @http_server[verb] path, (req, res) -> res.send String(response)
    else
      handler = new RequestHandler(response, @defs, @helpers, @postrenders, @views, @layouts, @vars)
      @http_server[verb] path, (req, res, next) ->
        handler.execute(req, res, next)

  using: ->
    pairs = {}
    for a in arguments
      pairs[a] = require(a)
    @def pairs
   
  def: (pairs) ->
    for k, v of pairs
      @defs[k] = v
   
  helper: (pairs) ->
    for k, v of pairs
      @helpers[k] = scoped(v)

  postrender: (pairs) ->
    jquery = require 'jquery'
    for k, v of pairs
      @postrenders[k] = scoped(v)

  at: (pairs) ->
    io = require 'socket.io'
    for k, v of pairs
      @socket_handlers[k] = new MessageHandler(v, @)

  msg: (pairs) ->
    io = require 'socket.io'
    for k, v of pairs
      @msg_handlers[k] = new MessageHandler(v, @)

  layout: (arg) ->
    pairs = if typeof arg is 'object' then arg else {default: arg}
    coffeekup = require 'coffeekup'
    for k, v of pairs
      @layouts[k] = v
   
  view: (arg) ->
    pairs = if typeof arg is 'object' then arg else {default: arg}
    coffeekup = require 'coffeekup'
    for k, v of pairs
      @views[k] = v

  client: (arg) ->
    pairs = if typeof arg is 'object' then arg else {default: arg}
    for k, v of pairs
      do (k, v) =>
        code = ";(#{v})();"
        @http_server.get "/#{k}.js", (req, res) ->
          res.contentType 'bla.js'
          res.send code

  style: (arg) ->
    pairs = if typeof arg is 'object' then arg else {default: arg}
    for k, v of pairs
      do (k, v) =>
        @http_server.get "/#{k}.css", (req, res) ->
          res.contentType 'bla.css'
          res.send v

class RequestHandler
  constructor: (handler, @defs, @helpers, @postrenders, @views, @layouts, @vars) ->
    @handler = scoped(handler)
    @locals = null

  init_locals: ->
    @locals = {}
    @locals.app = @vars
    @locals.render = @render
    @locals.partial = @partial
    @locals.redirect = @redirect
    @locals.send = @send
    @locals.puts = puts

    for k, v of @defs
      @locals[k] = v

    for k, v of @helpers
      do (k, v) =>
        @locals[k] = ->
          v(@context, @, arguments)

    @locals.defs = @defs
    @locals.postrenders = @postrenders
    @locals.views = @views
    @locals.layouts = @layouts

  execute: (request, response, next) ->
    @init_locals() unless @locals?

    @locals.context = {}
    @locals.params = @locals.context

    @locals.request = request
    @locals.response = response
    @locals.next = next

    @locals.session = request.session
    @locals.cookies = request.cookies

    for k, v of request.query
      @locals.context[k] = v
    for k, v of request.params
      @locals.context[k] = v
    for k, v of request.body
      @locals.context[k] = v

    result = @handler(@locals.context, @locals)

    if typeof result is 'string'
      response.send result
    else
      result

  redirect: -> @response.redirect.apply @response, arguments
  send: -> @response.send.apply @response, arguments

  render: (template, options) ->
    options ?= {}
    options.layout ?= 'default'

    opts = options.options or {} # Options for the templating engine.
    opts.context ?= @context
    opts.context.zappa = partial: @partial
    opts.locals ?= {}
    opts.locals.partial = (template, context) ->
      text ck_options.context.zappa.partial template, context

    template = @views[template] if typeof template is 'string'

    result = coffeekup.render template, opts

    if typeof options.apply is 'string'
      postrender = @postrenders[options.apply]
      body = jquery('body')
      body.empty().html(result)
      postrender opts.context, jquery.extend(@defs, {$: jquery})
      result = body.html()

    if options.layout
      layout = @layouts[options.layout]
      opts.context.content = result
      result = coffeekup.render layout, opts

    @response.send result

    null

  partial: (template, context) =>
    template = @views[template]
    coffeekup.render(template, context: context)

class MessageHandler
  constructor: (handler, @app) ->
    @handler = scoped(handler)
    @locals = null

  init_locals: ->
    @locals = {}
    @locals.app = @app.vars
    @locals.render = @render
    @locals.partial = @partial
    @locals.puts = puts
  
    for k, v of @app.defs
      @locals[k] = v

    for k, v of @app.helpers
      do (k, v) =>
        @locals[k] = ->
          v(@context, @, arguments)

    @locals.defs = @app.defs
    @locals.postrenders = @app.postrenders
    @locals.views = @app.views
    @locals.layouts = @app.layouts

  execute: (client, params) ->
    @init_locals() unless @locals?

    @locals.context = {}
    @locals.params = @locals.context
    @locals.client = client
    # TODO: Move this to context.
    @locals.id = client.sessionId
    @locals.send = (title, data) => client.send build_msg(title, data)
    @locals.broadcast = (title, data, except) =>
      except ?= []
      if except not instanceof Array then except = [except]
      except.push @locals.id
      @app.ws_server.broadcast build_msg(title, data), except

    for k, v of params
      @locals.context[k] = v

    @handler(@locals.context, @locals)

  render: (template, options) ->
    options ?= {}
    options.layout ?= 'default'

    opts = options.options or {} # Options for the templating engine.
    opts.context ?= @context
    opts.context.zappa = partial: @partial
    opts.locals ?= {}
    opts.locals.partial = (template, context) ->
      text ck_options.context.zappa.partial template, context

    template = @app.views[template] if typeof template is 'string'

    result = coffeekup.render template, opts

    if typeof options.apply is 'string'
      postrender = @postrenders[options.apply]
      body = jquery('body')
      body.empty().html(result)
      postrender opts.context, jquery.extend(@defs, {$: jquery})
      result = body.html()

    if options.layout
      layout = @layouts[options.layout]
      opts.context.content = result
      result = coffeekup.render layout, opts

    @send 'render', value: result

    null

  partial: (template, context) =>
    template = @app.views[template]
    coffeekup.render(template, context: context)

coffeescript_support = """
  var __slice = Array.prototype.slice;
  var __hasProp = Object.prototype.hasOwnProperty;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  var __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype;
    return child;
  };
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
"""

build_msg = (title, data) ->
  obj = {}
  obj[title] = data
  JSON.stringify(obj)

parse_msg = (raw_msg) ->
  obj = JSON.parse(raw_msg)
  for k, v of obj
    return {title: k, params: v}

scoped = (code) ->
  code = String(code)
  code = "function () {#{code}}" unless code.indexOf('function') is 0
  code = "#{coffeescript_support} with(locals) {return (#{code}).apply(context, args);}"
  new Function('context', 'locals', 'args', code)

publish_api = (from, to, methods) ->
  for name in methods.split '|'
    do (name) ->
      if typeof from[name] is 'function'
        to[name] = -> from[name].apply from, arguments
      else
        to[name] = from[name]

z = new Zappa()

zappa.version = '0.1.5'
zappa.run = -> z.run.apply z, arguments
zappa.run_file = -> z.run_file.apply z, arguments
