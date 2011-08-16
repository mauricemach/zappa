# Client-side zappa.
skeleton = ->
  zappa = window.zappa = {}
  zappa.version = null

  coffeescript_helpers = null
  rewrite_function = null

  zappa.run = (root_function) ->
    root_locals_names = ['app', 'socket', 'def', 'helper', 'get', 'connect', 'at', 'emit']
    sammy_locals_names = ['app', 'context', 'params', 'render', 'redirect']
    ws_locals_names = ['app', 'socket', 'id', 'params', 'emit']
    helpers_names = []
    defs_names = []

    # Storage for the functions provided by the user.
    routes = []
    ws_handlers = {}
    helpers = {}
    defs = {}

    app = Sammy() if Sammy?
    socket = null

    root_context = {}
    root_locals = {app, socket}

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
      
    root_locals.emit = ->
      socket.emit.apply socket, arguments

    # Executes the (rewriten) end-user function and learns how the app should be structured.
    rewritten_root = rewrite_function(root_function, root_locals_names)
    rewritten_root(root_context, root_locals)

    # Implements the application according to the specification.

    for k, v of helpers
      helpers[k] = rewrite_function(v, sammy_locals_names.concat(helpers_names).concat(defs_names))

    for k, v of ws_handlers
      ws_handlers[k] = rewrite_function(v, ws_locals_names.concat(helpers_names).concat(defs_names))

    for r in routes
      do (r) ->
        rewritten_handler = rewrite_function(r.handler,
          sammy_locals_names.concat(helpers_names).concat(defs_names))

        context = null
        locals = {app}

        for name, def of defs
          locals[name] = def

        for name, helper of helpers
          locals[name] = ->
            helper(context, locals, arguments)

        app.get r.path, (sammy_context) ->
          context = {}
          context[k] = v for k, v of sammy_context.params
          locals.params = context
          locals.context = sammy_context
          locals.render = -> sammy_context.render.apply res, arguments
          locals.redirect = -> sammy_context.redirect.apply res, arguments
          rewritten_handler(context, locals)

    # Implements the websockets client with socket.io.
    if socket?
      context = {}
      locals =
        app: app
        socket: socket
        id: socket.id
        emit: -> socket.emit.apply socket, arguments
      
      for name, def of defs
        locals[name] = def

      for name, helper of helpers
        do (name, helper) ->
          locals[name] = ->
            helper(context, locals, arguments)

      for name, h of ws_handlers
        do (name, h) ->
          socket.on name, (data) ->
            context = {}
            context[k] = v for k, v of data
            locals.params = context
            h(context, locals)

    $(-> app.run '#/') if app?

@build = (version, coffeescript_helpers, rewrite_function) ->
  String(skeleton)
    .replace('version = null;', "version = '#{version}';")
    .replace('coffeescript_helpers = null;', "var coffeescript_helpers = '#{coffeescript_helpers}';")
    .replace('rewrite_function = null;', "var rewrite_function = #{rewrite_function};")
    .replace /(\n)/g, ''