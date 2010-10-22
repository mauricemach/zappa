express = require 'express'
fs = require 'fs'
sys = require 'sys'
puts = sys.puts
coffeekup = null
coffee = null
jsdom = null
io = null

class Zappa
  @version: '0.1.0'
  @app_api: 'get|post|put|del|route|at|msg|client|using|def|helper|postrender|layout|view'.split '|'

  constructor: ->
    @locals = {}
    @locals.context = {}
    @locals.apps = {}
    @locals.current_app = null
    @locals.ensure_app = @ensure_app
    @locals.execute = @execute
    @locals.app = @app
    @locals.port = @port
    @locals.include = @include

    for name in Zappa.app_api
      @locals[name] = ->
        @ensure_app 'default' unless @current_app?
        @current_app[name].apply @current_app, arguments

  execute: (code) ->
    scoped(code)(@context, @)

  ensure_app: (name) ->
    @apps[name] = new App() unless @apps[name]?
    @current_app = @apps[name] unless @current_app?

  app: (name) ->
    if name?
      @ensure_app name
      @current_app = @apps[name]
      @current_app.name = name
    else
      for k, v of @apps
        return k if v is @current_app
      null

  port: (num) ->
    @ensure_app 'default' unless @current_app?
    @current_app.port = num
    
  include: (file) ->
    @execute js_from_file(file)

  run: (path) ->
    if path.indexOf('.coffee') > -1
      js = js_from_file(path)
    else
      js = fs.readFileSync path, 'utf8'

    @locals.execute js
    
    for k, v of @locals.apps
      v.start()

class App
  constructor: ->
    @name = 'default'
    @port = 8000
    
    @http_server = express.createServer()
    if coffeekup?
      @http_server.register '.coffee', coffeekup
      @http_server.set 'view engine', 'coffee'
    @http_server.configure =>
      @http_server.use express.staticProvider("#{process.cwd()}/public")

    @vars = {}
    
    @defs = {}
    @helpers = {}
    @postrenders = {}
    @socket_handlers = {}
    @msg_handlers = {}

    @views = {}
    @layouts = {}
    
  start: ->
    if io?
      @ws_server = io.listen @http_server, {log: ->}
      @ws_server.on 'connection', (client) => @socket_handlers.connection?.execute client
      @ws_server.on 'clientDisconnect', (client) => @socket_handlers.disconnection?.execute client
      @ws_server.on 'clientMessage', (raw_msg, client) =>
        msg = parse_msg raw_msg
        @msg_handlers[msg.title]?.execute client, msg.params

    @http_server.listen @port
    puts "App \"#{@name}\" listening on port #{@port}..."
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

  using: (name) ->
    pairs = {}
    pairs[name] = require(name)
    @def pairs
   
  def: (pairs) ->
    for k, v of pairs
      @defs[k] = v
   
  helper: (pairs) ->
    for k, v of pairs
      @helpers[k] = scoped(v)

  postrender: (pairs) ->
    jsdom = require 'jsdom'
    for k, v of pairs
      @postrenders[k] = scoped(v)

  at: (pairs) ->
    io = require 'socket.io'
    for k, v of pairs
      @socket_handlers[k] = new MessageHandler(v, @defs, @helpers, @postrenders, @views, @layouts, @vars)

  msg: (pairs) ->
    io = require 'socket.io'
    for k, v of pairs
      @msg_handlers[k] = new MessageHandler(v, @defs, @helpers, @postrenders, @views, @layouts, @vars)

  layout: (param) ->
    coffeekup = require 'coffeekup'
    if typeof param is 'object'
      for k, v of param
        @layouts[k] = v
    else
      @layouts['default'] = param
   
  view: (pairs) ->
    coffeekup = require 'coffeekup'
    for k, v of pairs
      @views[k] = v

  client: (pairs) ->
    for k, v of pairs
      code = ";(#{v})();"
      @http_server.get "/#{k}.js", (req, res) ->
        res.contentType 'bla.js'
        res.send code

class RequestHandler
  constructor: (handler, @defs, @helpers, @postrenders, @views, @layouts, @vars) ->
    @handler = scoped(handler)
    @locals = null

  init_locals: ->
    @locals = {}
    @locals.app = @vars
    @locals.render = @render
    @locals.redirect = @redirect
  
    for k, v of @defs
      @locals[k] = v

    for k, v of @helpers
      @locals[k] = ->
        v(@context, @, arguments)

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

  redirect: (path) -> @response.redirect(path)

  render: (what, options) ->
    options ?= {}
    layout = @layouts['default']
    view = if typeof what is 'function' then what else @views[what]

    inner = coffeekup.render view, context: @context

    if typeof options.apply is 'string'
      postrender = @postrenders[options.apply]
      new_doc ($) =>
        $('body').html inner
        postrender @context, {$: $}
        @context.content = $('body').html()
        html = coffeekup.render layout, context: @context
        @response.send html
    else
      @context.content = inner
      @response.send(coffeekup.render layout, context: @context)

    null

class MessageHandler
  constructor: (handler, @defs, @helpers, @postrenders, @views, @layouts, @vars) ->
    @handler = scoped(handler)
    @locals = null

  init_locals: ->
    @locals = {}
    @locals.app = @vars
    @locals.render = @render
  
    for k, v of @defs
      @locals[k] = v

    for k, v of @helpers
      @locals[k] = ->
        v(@context, @, arguments)

    @locals.postrenders = @postrenders
    @locals.views = @views
    @locals.layouts = @layouts

  execute: (client, params) ->
    @init_locals() unless @locals?

    @locals.context = {}
    @locals.params = @locals.context
    @locals.client = client
    @locals.id = client.sessionId
    @locals.send = (title, data) -> client.send build_msg(title, data)
    @locals.broadcast = (title, data) -> client.broadcast build_msg(title, data)

    for k, v of params
      @locals.context[k] = v

    @handler(@locals.context, @locals)

  render: (what, options) ->
    options ?= {}
    layout = @layouts['default']
    view = if typeof what is 'function' then what else @views[what]

    inner = coffeekup.render view, context: @context

    if typeof options.apply is 'string'
      postrender = @postrenders[options.apply]
      new_doc ($) =>
        $('body').html inner
        postrender @context, {$: $}
        @context.content = $('body').html()
        html = coffeekup.render layout, context: @context
        @send 'render', value: html
    else
      @context.content = inner
      @send 'render', value: (coffeekup.render layout, context: @context)

build_msg = (title, data) ->
  obj = {}
  obj[title] = data
  JSON.stringify(obj)

parse_msg = (raw_msg) ->
  obj = JSON.parse(raw_msg)
  for k, v of obj
    return {title: k, params: v}

js_from_file = (file) ->
  coffee = require 'coffee-script'
  code = fs.readFileSync file, 'utf8'
  coffee.compile code

new_doc = (cb) ->
  window = jsdom.jsdom().createWindow()
  jsdom.jQueryify window, "#{__dirname}/jquery-1.4.2-min.js", (window, $) -> cb($)
    
scoped = (code) ->
  bind = 'var __bind = function(func, context){return function(){return func.apply(context, arguments);};};'
  code = String(code)
  code = "function () {#{code}}" unless code.indexOf('function') is 0
  code = "#{bind} with(locals) {return (#{code}).apply(context, args);}"
  new Function('context', 'locals', 'args', code)

publish_api = (from, to, methods) ->
  for name in methods.split '|'
    if typeof from[name] is 'function'
      to[name] = -> from[name].apply from, arguments
    else
      to[name] = from[name]
  
zappa = new Zappa()
exports.version = Zappa.version
publish_api zappa, exports, 'run'
