(function() {
  var App, MessageHandler, RequestHandler, Zappa, build_msg, coffee, coffeekup, express, fs, io, jquery, parse_msg, publish_api, puts, scoped, sys, z, zappa;
  var __bind = function(func, context) {
    return function(){ return func.apply(context, arguments); };
  }, __hasProp = Object.prototype.hasOwnProperty;
  zappa = exports;
  express = require('express');
  fs = require('fs');
  sys = require('sys');
  puts = sys.puts;
  coffee = null;
  jquery = require('jquery');
  io = null;
  coffeekup = null;
  Zappa = function() {
    var _i, _len, _ref;
    this.context = {};
    this.apps = {};
    this.current_app = null;
    this.locals = {
      app: __bind(function(name) {
        return this.app(name);
      }, this),
      include: __bind(function(path) {
        return this.include(path);
      }, this),
      require: require
    };
    _ref = 'get|post|put|del|route|at|msg|client|using|def|helper|postrender|layout|view|style'.split('|');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      (function() {
        var name = _ref[_i];
        return (this.locals[name] = __bind(function() {
          var _ref2;
          if (!(typeof (_ref2 = this.current_app) !== "undefined" && _ref2 !== null)) {
            this.ensure_app('default');
          }
          return this.current_app[name].apply(this.current_app, arguments);
        }, this));
      }).call(this);
    }
    return this;
  };
  Zappa.prototype.app = function(name) {
    this.ensure_app(name);
    return (this.current_app = this.apps[name]);
  };
  Zappa.prototype.include = function(file) {
    this.define_with(this.read_and_compile(file));
    return puts("Included file \"" + (file) + "\"");
  };
  Zappa.prototype.define_with = function(code) {
    return scoped(code)(this.context, this.locals);
  };
  Zappa.prototype.ensure_app = function(name) {
    var _ref;
    if (!(typeof (_ref = this.apps[name]) !== "undefined" && _ref !== null)) {
      this.apps[name] = new App(name);
    }
    if (!(typeof (_ref = this.current_app) !== "undefined" && _ref !== null)) {
      return (this.current_app = this.apps[name]);
    }
  };
  Zappa.prototype.read_and_compile = function(file) {
    var code;
    coffee = require('coffee-script');
    code = this.read(file);
    return coffee.compile(code);
  };
  Zappa.prototype.read = function(file) {
    return fs.readFileSync(file, 'utf8');
  };
  Zappa.prototype.run_file = function(file, options) {
    var code;
    code = file.match(/\.coffee$/) ? this.read_and_compile(file) : this.read(file);
    return this.run(code, options);
  };
  Zappa.prototype.run = function(code, options) {
    var _ref, _ref2, _result, a, i, k, opts;
    options = (typeof options !== "undefined" && options !== null) ? options : {};
    this.define_with(code);
    i = 0;
    _result = []; _ref = this.apps;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      a = _ref[k];
      _result.push((function() {
        opts = {};
        if (options.port) {
          opts.port = (typeof (_ref2 = options.port[i]) !== "undefined" && _ref2 !== null) ? options.port[i] : a.port + i;
        } else if (i !== 0) {
          opts.port = a.port + i;
        }
        a.start(opts);
        return i++;
      })());
    }
    return _result;
  };
  App = function(_arg) {
    this.name = _arg;
    this.name = (typeof this.name !== "undefined" && this.name !== null) ? this.name : 'default';
    this.port = 5678;
    this.http_server = express.createServer();
    if (typeof coffeekup !== "undefined" && coffeekup !== null) {
      this.http_server.register('.coffee', coffeekup);
      this.http_server.set('view engine', 'coffee');
    }
    this.http_server.configure(__bind(function() {
      this.http_server.use(express.staticProvider("" + (process.cwd()) + "/public"));
      this.http_server.use(express.bodyDecoder());
      this.http_server.use(express.cookieDecoder());
      return this.http_server.use(express.session());
    }, this));
    this.vars = {};
    this.defs = {};
    this.helpers = {};
    this.postrenders = {};
    this.socket_handlers = {};
    this.msg_handlers = {};
    this.views = {};
    this.layouts = {};
    this.layouts["default"] = function() {
      doctype(5);
      return html(function() {
        head(function() {
          var _i, _len, _ref, s;
          if (this.title) {
            title(this.title);
          }
          if (this.scripts) {
            _ref = this.scripts;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              s = _ref[_i];
              script({
                src: s + '.js'
              });
            }
          }
          if (this.script) {
            script({
              src: this.script + '.js'
            });
          }
          if (this.stylesheets) {
            _ref = this.stylesheets;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              s = _ref[_i];
              link({
                rel: 'stylesheet',
                href: s + '.css'
              });
            }
          }
          if (this.stylesheet) {
            link({
              rel: 'stylesheet',
              href: this.stylesheet + '.css'
            });
          }
          if (this.style) {
            return style(this.style);
          }
        });
        return body(this.content);
      });
    };
    return this;
  };
  App.prototype.start = function(options) {
    options = (typeof options !== "undefined" && options !== null) ? options : {};
    if (options.port) {
      this.port = options.port;
    }
    if (typeof io !== "undefined" && io !== null) {
      this.ws_server = io.listen(this.http_server, {
        log: function() {}
      });
      this.ws_server.on('connection', __bind(function(client) {
        this.socket_handlers.connection == null ? undefined : this.socket_handlers.connection.execute(client);
        client.on('disconnect', __bind(function() {
          return this.socket_handlers.disconnection == null ? undefined : this.socket_handlers.disconnection.execute(client);
        }, this));
        return client.on('message', __bind(function(raw_msg) {
          var msg;
          msg = parse_msg(raw_msg);
          return this.msg_handlers[msg.title] == null ? undefined : this.msg_handlers[msg.title].execute(client, msg.params);
        }, this));
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
  App.prototype.using = function() {
    var _i, _len, _ref, a, pairs;
    pairs = {};
    _ref = arguments;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      a = _ref[_i];
      pairs[a] = require(a);
    }
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
    var _ref, _result, jsdom, k, v;
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
  App.prototype.layout = function(arg) {
    var _ref, _result, k, pairs, v;
    pairs = typeof arg === 'object' ? arg : {
      "default": arg
    };
    coffeekup = require('coffeekup');
    _result = []; _ref = pairs;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      _result.push(this.layouts[k] = v);
    }
    return _result;
  };
  App.prototype.view = function(arg) {
    var _ref, _result, k, pairs, v;
    pairs = typeof arg === 'object' ? arg : {
      "default": arg
    };
    coffeekup = require('coffeekup');
    _result = []; _ref = pairs;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      _result.push(this.views[k] = v);
    }
    return _result;
  };
  App.prototype.client = function(arg) {
    var _i, _ref, _result, k, pairs;
    pairs = typeof arg === 'object' ? arg : {
      "default": arg
    };
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
  App.prototype.style = function(arg) {
    var _i, _ref, _result, k, pairs;
    pairs = typeof arg === 'object' ? arg : {
      "default": arg
    };
    _result = []; _ref = pairs;
    for (_i in _ref) {
      if (!__hasProp.call(_ref, _i)) continue;
      (function() {
        var k = _i;
        var v = _ref[_i];
        return _result.push(this.http_server.get("/" + (k) + ".css", function(req, res) {
          res.contentType('bla.css');
          return res.send(v);
        }));
      }).call(this);
    }
    return _result;
  };
  RequestHandler = function(handler, _arg, _arg2, _arg3, _arg4, _arg5, _arg6) {
    var _this;
    this.vars = _arg6;
    this.layouts = _arg5;
    this.views = _arg4;
    this.postrenders = _arg3;
    this.helpers = _arg2;
    this.defs = _arg;
    _this = this;
    this.partial = function(){ return RequestHandler.prototype.partial.apply(_this, arguments); };
    this.handler = scoped(handler);
    this.locals = null;
    return this;
  };
  RequestHandler.prototype.init_locals = function() {
    var _i, _ref, k, v;
    this.locals = {};
    this.locals.app = this.vars;
    this.locals.render = this.render;
    this.locals.partial = this.partial;
    this.locals.redirect = this.redirect;
    this.locals.send = this.send;
    this.locals.puts = puts;
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
  RequestHandler.prototype.redirect = function() {
    return this.response.redirect.apply(this.response, arguments);
  };
  RequestHandler.prototype.send = function() {
    return this.response.send.apply(this.response, arguments);
  };
  RequestHandler.prototype.render = function(template, options) {
    var body, layout, opts, postrender, result;
    options = (typeof options !== "undefined" && options !== null) ? options : {};
    options.layout = (typeof options.layout !== "undefined" && options.layout !== null) ? options.layout : 'default';
    opts = options.options || {};
    opts.context = (typeof opts.context !== "undefined" && opts.context !== null) ? opts.context : this.context;
    opts.context.zappa = {
      partial: this.partial
    };
    opts.locals = (typeof opts.locals !== "undefined" && opts.locals !== null) ? opts.locals : {};
    opts.locals.partial = function(template, context) {
      return text(ck_options.context.zappa.partial(template, context));
    };
    if (typeof template === 'string') {
      template = this.views[template];
    }
    result = coffeekup.render(template, opts);
    if (typeof options.apply === 'string') {
      postrender = this.postrenders[options.apply];
      body = jquery('body');
      body.empty().html(result);
      postrender(opts.context, {
        $: jquery
      });
      result = body.html();
    }
    if (options.layout) {
      layout = this.layouts[options.layout];
      opts.context.content = result;
      result = coffeekup.render(layout, opts);
    }
    this.response.send(result);
    return null;
  };
  RequestHandler.prototype.partial = function(template, context) {
    template = this.views[template];
    return coffeekup.render(template, {
      context: context
    });
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
    this.locals.puts = puts;
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
    var body, html, inner, layout, postrender, result, view;
    options = (typeof options !== "undefined" && options !== null) ? options : {};
    layout = this.layouts["default"];
    view = typeof what === 'function' ? what : this.views[what];
    inner = coffeekup.render(view, {
      context: this.context
    });
    if (typeof options.apply === 'string') {
      postrender = this.postrenders[options.apply];
      body = jquery('body');
      body.empty().html(inner);
      postrender(this.context, {
        $: jquery
      });
      result = body.html();
      if (options.layout) {
        this.context.content = result;
        html = coffeekup.render(layout, {
          context: this.context
        });
        return this.send('render', {
          value: html
        });
      }
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
  z = new Zappa();
  zappa.version = '0.1.2';
  zappa.run = function() {
    return z.run.apply(z, arguments);
  };
  zappa.run_file = function() {
    return z.run_file.apply(z, arguments);
  };
}).call(this);
