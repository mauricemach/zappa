# Client-side zappa.
skeleton = ->
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

@build = (version, coffeescript_helpers, rewrite_function) ->
  String(skeleton)
    .replace('version = null;', "version = '#{version}';")
    .replace('coffeescript_helpers = null;', "var coffeescript_helpers = '#{coffeescript_helpers}';")
    .replace('rewrite_function = null;', "var rewrite_function = #{rewrite_function};")
    .replace /(\n)/g, ''