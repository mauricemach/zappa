(function() {
  var App, MessageHandler, RequestHandler, Zappa, build_msg, coffee, coffeekup, express, fs, io, js_from_file, jsdom, new_doc, parse_msg, publish_api, puts, scoped, sys, zappa;
  var __hasProp = Object.prototype.hasOwnProperty, __bind = function(func, context) {
    return function(){ return func.apply(context, arguments); };
  };
  express = require('express');
  fs = require('fs');
  sys = require('sys');
  puts = sys.puts;
  coffeekup = null;
  coffee = null;
  jsdom = null;
  io = null;
  Zappa = function() {
    var _i, _len, _ref;
    this.locals = {};
    this.locals.context = {};
    this.locals.apps = {};
    this.locals.current_app = null;
    this.locals.ensure_app = this.ensure_app;
    this.locals.execute = this.execute;
    this.locals.app = this.app;
    this.locals.port = this.port;
    this.locals.include = this.include;
    _ref = Zappa.app_api;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      (function() {
        var name = _ref[_i];
        return (this.locals[name] = function() {
          var _ref2;
          if (!(typeof (_ref2 = this.current_app) !== "undefined" && _ref2 !== null)) {
            this.ensure_app('default');
          }
          return this.current_app[name].apply(this.current_app, arguments);
        });
      }).call(this);
    }
    return this;
  };
  Zappa.version = '0.1.0';
  Zappa.app_api = 'get|post|put|del|route|at|msg|client|using|def|helper|postrender|layout|view'.split('|');
  Zappa.prototype.execute = function(code) {
    return scoped(code)(this.context, this);
  };
  Zappa.prototype.ensure_app = function(name) {
    var _ref;
    if (!(typeof (_ref = this.apps[name]) !== "undefined" && _ref !== null)) {
      this.apps[name] = new App();
    }
    if (!(typeof (_ref = this.current_app) !== "undefined" && _ref !== null)) {
      return (this.current_app = this.apps[name]);
    }
  };
  Zappa.prototype.app = function(name) {
    var _ref, k, v;
    if (typeof name !== "undefined" && name !== null) {
      this.ensure_app(name);
      this.current_app = this.apps[name];
      return (this.current_app.name = name);
    } else {
      _ref = this.apps;
      for (k in _ref) {
        if (!__hasProp.call(_ref, k)) continue;
        v = _ref[k];
        if (v === this.current_app) {
          return k;
        }
      }
      return null;
    }
  };
  Zappa.prototype.port = function(num) {
    var _ref;
    if (!(typeof (_ref = this.current_app) !== "undefined" && _ref !== null)) {
      this.ensure_app('default');
    }
    return (this.current_app.port = num);
  };
  Zappa.prototype.include = function(file) {
    return this.execute(js_from_file(file));
  };
  Zappa.prototype.run = function(path) {
    var _ref, _result, js, k, v;
    if (path.indexOf('.coffee') > -1) {
      js = js_from_file(path);
    } else {
      js = fs.readFileSync(path, 'utf8');
    }
    this.locals.execute(js);
    _result = []; _ref = this.locals.apps;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      _result.push(v.start());
    }
    return _result;
  };
  App = function() {
    this.name = 'default';
    this.port = 8000;
    this.http_server = express.createServer();
    if (typeof coffeekup !== "undefined" && coffeekup !== null) {
      this.http_server.register('.coffee', coffeekup);
      this.http_server.set('view engine', 'coffee');
    }
    this.http_server.configure(__bind(function() {
      return this.http_server.use(express.staticProvider("" + (process.cwd()) + "/public"));
    }, this));
    this.vars = {};
    this.defs = {};
    this.helpers = {};
    this.postrenders = {};
    this.socket_handlers = {};
    this.msg_handlers = {};
    this.views = {};
    this.layouts = {};
    return this;
  };
  App.prototype.start = function() {
    if (typeof io !== "undefined" && io !== null) {
      this.ws_server = io.listen(this.http_server, {
        log: function() {}
      });
      this.ws_server.on('connection', __bind(function(client) {
        return this.socket_handlers.connection == null ? undefined : this.socket_handlers.connection.execute(client);
      }, this));
      this.ws_server.on('clientDisconnect', __bind(function(client) {
        return this.socket_handlers.disconnection == null ? undefined : this.socket_handlers.disconnection.execute(client);
      }, this));
      this.ws_server.on('clientMessage', __bind(function(raw_msg, client) {
        var msg;
        msg = parse_msg(raw_msg);
        return this.msg_handlers[msg.title] == null ? undefined : this.msg_handlers[msg.title].execute(client, msg.params);
      }, this));
    }
    this.http_server.listen(this.port);
    puts("App \"" + (this.name) + "\" listening on port " + (this.port) + "...");
    return this.http_server;
  };
  App.prototype.get = function() {
    return this.route('get', arguments);
  };
  App.prototype.post = function() {
    return this.route('post', arguments);
  };
  App.prototype.put = function() {
    return this.route('put', arguments);
  };
  App.prototype.del = function() {
    return this.route('del', arguments);
  };
  App.prototype.route = function(verb, args) {
    var _ref, _result, k, v;
    if (typeof args[0] !== 'object') {
      return this.register_route(verb, args[0], args[1]);
    } else {
      _result = []; _ref = args[0];
      for (k in _ref) {
        if (!__hasProp.call(_ref, k)) continue;
        v = _ref[k];
        _result.push(this.register_route(verb, k, v));
      }
      return _result;
    }
  };
  App.prototype.register_route = function(verb, path, response) {
    var handler;
    if (typeof response !== 'function') {
      return this.http_server[verb](path, function(req, res) {
        return res.send(String(response));
      });
    } else {
      handler = new RequestHandler(response, this.defs, this.helpers, this.postrenders, this.views, this.layouts, this.vars);
      return this.http_server[verb](path, function(req, res, next) {
        return handler.execute(req, res, next);
      });
    }
  };
  App.prototype.using = function(name) {
    var pairs;
    pairs = {};
    pairs[name] = require(name);
    return this.def(pairs);
  };
  App.prototype.def = function(pairs) {
    var _ref, _result, k, v;
    _result = []; _ref = pairs;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      _result.push(this.defs[k] = v);
    }
    return _result;
  };
  App.prototype.helper = function(pairs) {
    var _ref, _result, k, v;
    _result = []; _ref = pairs;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      _result.push(this.helpers[k] = scoped(v));
    }
    return _result;
  };
  App.prototype.postrender = function(pairs) {
    var _ref, _result, k, v;
    jsdom = require('jsdom');
    _result = []; _ref = pairs;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      _result.push(this.postrenders[k] = scoped(v));
    }
    return _result;
  };
  App.prototype.at = function(pairs) {
    var _ref, _result, k, v;
    io = require('socket.io');
    _result = []; _ref = pairs;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      _result.push(this.socket_handlers[k] = new MessageHandler(v, this.defs, this.helpers, this.postrenders, this.views, this.layouts, this.vars));
    }
    return _result;
  };
  App.prototype.msg = function(pairs) {
    var _ref, _result, k, v;
    io = require('socket.io');
    _result = []; _ref = pairs;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      _result.push(this.msg_handlers[k] = new MessageHandler(v, this.defs, this.helpers, this.postrenders, this.views, this.layouts, this.vars));
    }
    return _result;
  };
  App.prototype.layout = function(param) {
    var _ref, _result, k, v;
    coffeekup = require('coffeekup');
    if (typeof param === 'object') {
      _result = []; _ref = param;
      for (k in _ref) {
        if (!__hasProp.call(_ref, k)) continue;
        v = _ref[k];
        _result.push(this.layouts[k] = v);
      }
      return _result;
    } else {
      return (this.layouts['default'] = param);
    }
  };
  App.prototype.view = function(pairs) {
    var _ref, _result, k, v;
    coffeekup = require('coffeekup');
    _result = []; _ref = pairs;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      _result.push(this.views[k] = v);
    }
    return _result;
  };
  App.prototype.client = function(pairs) {
    var _i, _ref, _result, k;
    _result = []; _ref = pairs;
    for (_i in _ref) {
      if (!__hasProp.call(_ref, _i)) continue;
      (function() {
        var code;
        var k = _i;
        var v = _ref[_i];
        return _result.push((function() {
          code = (";(" + (v) + ")();");
          return this.http_server.get("/" + (k) + ".js", function(req, res) {
            res.contentType('bla.js');
            return res.send(code);
          });
        }).call(this));
      }).call(this);
    }
    return _result;
  };
  RequestHandler = function(handler, _arg, _arg2, _arg3, _arg4, _arg5, _arg6) {
    this.vars = _arg6;
    this.layouts = _arg5;
    this.views = _arg4;
    this.postrenders = _arg3;
    this.helpers = _arg2;
    this.defs = _arg;
    this.handler = scoped(handler);
    this.locals = null;
    return this;
  };
  RequestHandler.prototype.init_locals = function() {
    var _i, _ref, k, v;
    this.locals = {};
    this.locals.app = this.vars;
    this.locals.render = this.render;
    this.locals.redirect = this.redirect;
    _ref = this.defs;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      this.locals[k] = v;
    }
    _ref = this.helpers;
    for (_i in _ref) {
      if (!__hasProp.call(_ref, _i)) continue;
      (function() {
        var k = _i;
        var v = _ref[_i];
        return (this.locals[k] = function() {
          return v(this.context, this, arguments);
        });
      }).call(this);
    }
    this.locals.postrenders = this.postrenders;
    this.locals.views = this.views;
    return (this.locals.layouts = this.layouts);
  };
  RequestHandler.prototype.execute = function(request, response, next) {
    var _ref, k, result, v;
    if (!(typeof (_ref = this.locals) !== "undefined" && _ref !== null)) {
      this.init_locals();
    }
    this.locals.context = {};
    this.locals.params = this.locals.context;
    this.locals.request = request;
    this.locals.response = response;
    this.locals.next = next;
    this.locals.session = request.session;
    this.locals.cookies = request.cookies;
    _ref = request.query;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      this.locals.context[k] = v;
    }
    _ref = request.params;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      this.locals.context[k] = v;
    }
    _ref = request.body;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      this.locals.context[k] = v;
    }
    result = this.handler(this.locals.context, this.locals);
    return typeof result === 'string' ? response.send(result) : result;
  };
  RequestHandler.prototype.redirect = function(path) {
    return this.response.redirect(path);
  };
  RequestHandler.prototype.render = function(what, options) {
    var inner, layout, postrender, view;
    options = (typeof options !== "undefined" && options !== null) ? options : {};
    layout = this.layouts['default'];
    view = typeof what === 'function' ? what : this.views[what];
    inner = coffeekup.render(view, {
      context: this.context
    });
    if (typeof options.apply === 'string') {
      postrender = this.postrenders[options.apply];
      new_doc(__bind(function($) {
        var html;
        $('body').html(inner);
        postrender(this.context, {
          $: $
        });
        this.context.content = $('body').html();
        html = coffeekup.render(layout, {
          context: this.context
        });
        return this.response.send(html);
      }, this));
    } else {
      this.context.content = inner;
      this.response.send(coffeekup.render(layout, {
        context: this.context
      }));
    }
    return null;
  };
  MessageHandler = function(handler, _arg, _arg2, _arg3, _arg4, _arg5, _arg6) {
    this.vars = _arg6;
    this.layouts = _arg5;
    this.views = _arg4;
    this.postrenders = _arg3;
    this.helpers = _arg2;
    this.defs = _arg;
    this.handler = scoped(handler);
    this.locals = null;
    return this;
  };
  MessageHandler.prototype.init_locals = function() {
    var _i, _ref, k, v;
    this.locals = {};
    this.locals.app = this.vars;
    this.locals.render = this.render;
    _ref = this.defs;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      this.locals[k] = v;
    }
    _ref = this.helpers;
    for (_i in _ref) {
      if (!__hasProp.call(_ref, _i)) continue;
      (function() {
        var k = _i;
        var v = _ref[_i];
        return (this.locals[k] = function() {
          return v(this.context, this, arguments);
        });
      }).call(this);
    }
    this.locals.postrenders = this.postrenders;
    this.locals.views = this.views;
    return (this.locals.layouts = this.layouts);
  };
  MessageHandler.prototype.execute = function(client, params) {
    var _ref, k, v;
    if (!(typeof (_ref = this.locals) !== "undefined" && _ref !== null)) {
      this.init_locals();
    }
    this.locals.context = {};
    this.locals.params = this.locals.context;
    this.locals.client = client;
    this.locals.id = client.sessionId;
    this.locals.send = function(title, data) {
      return client.send(build_msg(title, data));
    };
    this.locals.broadcast = function(title, data) {
      return client.broadcast(build_msg(title, data));
    };
    _ref = params;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      this.locals.context[k] = v;
    }
    return this.handler(this.locals.context, this.locals);
  };
  MessageHandler.prototype.render = function(what, options) {
    var inner, layout, postrender, view;
    options = (typeof options !== "undefined" && options !== null) ? options : {};
    layout = this.layouts['default'];
    view = typeof what === 'function' ? what : this.views[what];
    inner = coffeekup.render(view, {
      context: this.context
    });
    if (typeof options.apply === 'string') {
      postrender = this.postrenders[options.apply];
      return new_doc(__bind(function($) {
        var html;
        $('body').html(inner);
        postrender(this.context, {
          $: $
        });
        this.context.content = $('body').html();
        html = coffeekup.render(layout, {
          context: this.context
        });
        return this.send('render', {
          value: html
        });
      }, this));
    } else {
      this.context.content = inner;
      return this.send('render', {
        value: (coffeekup.render(layout, {
          context: this.context
        }))
      });
    }
  };
  build_msg = function(title, data) {
    var obj;
    obj = {};
    obj[title] = data;
    return JSON.stringify(obj);
  };
  parse_msg = function(raw_msg) {
    var _ref, _result, k, obj, v;
    obj = JSON.parse(raw_msg);
    _result = []; _ref = obj;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      return {
        title: k,
        params: v
      };
    }
    return _result;
  };
  js_from_file = function(file) {
    var code;
    coffee = require('coffee-script');
    code = fs.readFileSync(file, 'utf8');
    return coffee.compile(code);
  };
  new_doc = function(cb) {
    var window;
    window = jsdom.jsdom().createWindow();
    return jsdom.jQueryify(window, "" + (__dirname) + "/jquery-1.4.2-min.js", function(window, $) {
      return cb($);
    });
  };
  scoped = function(code) {
    var bind;
    bind = 'var __bind = function(func, context){return function(){return func.apply(context, arguments);};};';
    code = String(code);
    if (code.indexOf('function') !== 0) {
      code = ("function () {" + (code) + "}");
    }
    code = ("" + (bind) + " with(locals) {return (" + (code) + ").apply(context, args);}");
    return new Function('context', 'locals', 'args', code);
  };
  publish_api = function(from, to, methods) {
    var _i, _len, _ref, _result;
    _result = []; _ref = methods.split('|');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      (function() {
        var name = _ref[_i];
        return _result.push(typeof from[name] === 'function' ? (to[name] = function() {
          return from[name].apply(from, arguments);
        }) : (to[name] = from[name]));
      })();
    }
    return _result;
  };
  zappa = new Zappa();
  exports.version = Zappa.version;
  publish_api(zappa, exports, 'run');
}).call(this);
