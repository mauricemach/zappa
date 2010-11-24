(function() {
  var App, MessageHandler, RequestHandler, Zappa, build_msg, coffee, coffeekup, coffeescript_support, express, fs, io, jquery, parse_msg, publish_api, puts, scoped, z, zappa;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty;
  zappa = exports;
  express = require('express');
  fs = require('fs');
  puts = console.log;
  coffee = null;
  jquery = require('jquery');
  io = null;
  coffeekup = null;
  Zappa = function() {
    function Zappa() {
      var _fn, _i, _len, _ref;
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
      _fn = function(name) {
        return this.locals[name] = __bind(function() {
          if (this.current_app == null) {
            this.ensure_app('default');
          }
          return this.current_app[name].apply(this.current_app, arguments);
        }, this);
      };
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        name = _ref[_i];
        _fn.call(this, name);
      }
    }
    Zappa.prototype.app = function(name) {
      this.ensure_app(name);
      return this.current_app = this.apps[name];
    };
    Zappa.prototype.include = function(file) {
      this.define_with(this.read_and_compile(file));
      return puts("Included file \"" + file + "\"");
    };
    Zappa.prototype.define_with = function(code) {
      return scoped(code)(this.context, this.locals);
    };
    Zappa.prototype.ensure_app = function(name) {
      if (this.apps[name] == null) {
        this.apps[name] = new App(name);
      }
      if (this.current_app == null) {
        return this.current_app = this.apps[name];
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
      var a, i, k, opts, _ref, _results;
      options != null ? options : options = {};
      this.define_with(code);
      i = 0;
      _ref = this.apps;
      _results = [];
      for (k in _ref) {
        if (!__hasProp.call(_ref, k)) continue;
        a = _ref[k];
        opts = {};
        if (options.port) {
          opts.port = options.port[i] != null ? options.port[i] : a.port + i;
        } else if (i !== 0) {
          opts.port = a.port + i;
        }
        a.start(opts);
        _results.push(i++);
      }
      return _results;
    };
    return Zappa;
  }();
  App = function() {
    function App(name) {
      var _ref;
      this.name = name;
      (_ref = this.name) != null ? _ref : this.name = 'default';
      this.port = 5678;
      this.http_server = express.createServer();
      if (coffeekup != null) {
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
            var s, _i, _j, _len, _len2, _ref, _ref2;
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
              _ref2 = this.stylesheets;
              for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
                s = _ref2[_j];
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
    }
    App.prototype.start = function(options) {
      options != null ? options : options = {};
      if (options.port) {
        this.port = options.port;
      }
      if (io != null) {
        this.ws_server = io.listen(this.http_server, {
          log: function() {}
        });
        this.ws_server.on('connection', __bind(function(client) {
          var _ref;
          if ((_ref = this.socket_handlers.connection) != null) {
            _ref.execute(client);
          }
          client.on('disconnect', __bind(function() {
            var _ref;
            return (_ref = this.socket_handlers.disconnection) != null ? _ref.execute(client) : void 0;
          }, this));
          return client.on('message', __bind(function(raw_msg) {
            var msg, _ref;
            msg = parse_msg(raw_msg);
            return (_ref = this.msg_handlers[msg.title]) != null ? _ref.execute(client, msg.params) : void 0;
          }, this));
        }, this));
      }
      this.http_server.listen(this.port);
      puts("App \"" + this.name + "\" listening on port " + this.port + "...");
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
      var k, v, _ref, _results;
      if (typeof args[0] !== 'object') {
        return this.register_route(verb, args[0], args[1]);
      } else {
        _ref = args[0];
        _results = [];
        for (k in _ref) {
          if (!__hasProp.call(_ref, k)) continue;
          v = _ref[k];
          _results.push(this.register_route(verb, k, v));
        }
        return _results;
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
      var a, pairs, _i, _len;
      pairs = {};
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        a = arguments[_i];
        pairs[a] = require(a);
      }
      return this.def(pairs);
    };
    App.prototype.def = function(pairs) {
      var k, v, _results;
      _results = [];
      for (k in pairs) {
        if (!__hasProp.call(pairs, k)) continue;
        v = pairs[k];
        _results.push(this.defs[k] = v);
      }
      return _results;
    };
    App.prototype.helper = function(pairs) {
      var k, v, _results;
      _results = [];
      for (k in pairs) {
        if (!__hasProp.call(pairs, k)) continue;
        v = pairs[k];
        _results.push(this.helpers[k] = scoped(v));
      }
      return _results;
    };
    App.prototype.postrender = function(pairs) {
      var jsdom, k, v, _results;
      jsdom = require('jsdom');
      _results = [];
      for (k in pairs) {
        if (!__hasProp.call(pairs, k)) continue;
        v = pairs[k];
        _results.push(this.postrenders[k] = scoped(v));
      }
      return _results;
    };
    App.prototype.at = function(pairs) {
      var k, v, _results;
      io = require('socket.io');
      _results = [];
      for (k in pairs) {
        if (!__hasProp.call(pairs, k)) continue;
        v = pairs[k];
        _results.push(this.socket_handlers[k] = new MessageHandler(v, this.defs, this.helpers, this.postrenders, this.views, this.layouts, this.vars));
      }
      return _results;
    };
    App.prototype.msg = function(pairs) {
      var k, v, _results;
      io = require('socket.io');
      _results = [];
      for (k in pairs) {
        if (!__hasProp.call(pairs, k)) continue;
        v = pairs[k];
        _results.push(this.msg_handlers[k] = new MessageHandler(v, this.defs, this.helpers, this.postrenders, this.views, this.layouts, this.vars));
      }
      return _results;
    };
    App.prototype.layout = function(arg) {
      var k, pairs, v, _results;
      pairs = typeof arg === 'object' ? arg : {
        "default": arg
      };
      coffeekup = require('coffeekup');
      _results = [];
      for (k in pairs) {
        if (!__hasProp.call(pairs, k)) continue;
        v = pairs[k];
        _results.push(this.layouts[k] = v);
      }
      return _results;
    };
    App.prototype.view = function(arg) {
      var k, pairs, v, _results;
      pairs = typeof arg === 'object' ? arg : {
        "default": arg
      };
      coffeekup = require('coffeekup');
      _results = [];
      for (k in pairs) {
        if (!__hasProp.call(pairs, k)) continue;
        v = pairs[k];
        _results.push(this.views[k] = v);
      }
      return _results;
    };
    App.prototype.client = function(arg) {
      var pairs, _fn, _results;
      pairs = typeof arg === 'object' ? arg : {
        "default": arg
      };
      _fn = function(k, v) {
        var code;
        code = ";(" + v + ")();";
        return _results.push(this.http_server.get("/" + k + ".js", function(req, res) {
          res.contentType('bla.js');
          return res.send(code);
        }));
      };
      _results = [];
      for (k in pairs) {
        if (!__hasProp.call(pairs, k)) continue;
        v = pairs[k];
        _fn.call(this, k, v);
      }
      return _results;
    };
    App.prototype.style = function(arg) {
      var pairs, _fn, _results;
      pairs = typeof arg === 'object' ? arg : {
        "default": arg
      };
      _fn = function(k, v) {
        return _results.push(this.http_server.get("/" + k + ".css", function(req, res) {
          res.contentType('bla.css');
          return res.send(v);
        }));
      };
      _results = [];
      for (k in pairs) {
        if (!__hasProp.call(pairs, k)) continue;
        v = pairs[k];
        _fn.call(this, k, v);
      }
      return _results;
    };
    return App;
  }();
  RequestHandler = function() {
    function RequestHandler(handler, defs, helpers, postrenders, views, layouts, vars) {
      this.defs = defs;
      this.helpers = helpers;
      this.postrenders = postrenders;
      this.views = views;
      this.layouts = layouts;
      this.vars = vars;
      this.partial = __bind(this.partial, this);;
      this.handler = scoped(handler);
      this.locals = null;
    }
    RequestHandler.prototype.init_locals = function() {
      var k, v, _fn, _ref, _ref2;
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
      _ref2 = this.helpers;
      _fn = function(k, v) {
        return this.locals[k] = function() {
          return v(this.context, this, arguments);
        };
      };
      for (k in _ref2) {
        if (!__hasProp.call(_ref2, k)) continue;
        v = _ref2[k];
        _fn.call(this, k, v);
      }
      this.locals.postrenders = this.postrenders;
      this.locals.views = this.views;
      return this.locals.layouts = this.layouts;
    };
    RequestHandler.prototype.execute = function(request, response, next) {
      var k, result, v, _ref, _ref2, _ref3;
      if (this.locals == null) {
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
      _ref2 = request.params;
      for (k in _ref2) {
        if (!__hasProp.call(_ref2, k)) continue;
        v = _ref2[k];
        this.locals.context[k] = v;
      }
      _ref3 = request.body;
      for (k in _ref3) {
        if (!__hasProp.call(_ref3, k)) continue;
        v = _ref3[k];
        this.locals.context[k] = v;
      }
      result = this.handler(this.locals.context, this.locals);
      if (typeof result === 'string') {
        return response.send(result);
      } else {
        return result;
      }
    };
    RequestHandler.prototype.redirect = function() {
      return this.response.redirect.apply(this.response, arguments);
    };
    RequestHandler.prototype.send = function() {
      return this.response.send.apply(this.response, arguments);
    };
    RequestHandler.prototype.render = function(template, options) {
      var body, layout, opts, postrender, result, _ref, _ref2, _ref3;
      options != null ? options : options = {};
      (_ref = options.layout) != null ? _ref : options.layout = 'default';
      opts = options.options || {};
      (_ref2 = opts.context) != null ? _ref2 : opts.context = this.context;
      opts.context.zappa = {
        partial: this.partial
      };
      (_ref3 = opts.locals) != null ? _ref3 : opts.locals = {};
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
    return RequestHandler;
  }();
  MessageHandler = function() {
    function MessageHandler(handler, defs, helpers, postrenders, views, layouts, vars) {
      this.defs = defs;
      this.helpers = helpers;
      this.postrenders = postrenders;
      this.views = views;
      this.layouts = layouts;
      this.vars = vars;
      this.partial = __bind(this.partial, this);;
      this.handler = scoped(handler);
      this.locals = null;
    }
    MessageHandler.prototype.init_locals = function() {
      var k, v, _fn, _ref, _ref2;
      this.locals = {};
      this.locals.app = this.vars;
      this.locals.render = this.render;
      this.locals.partial = this.partial;
      this.locals.puts = puts;
      _ref = this.defs;
      for (k in _ref) {
        if (!__hasProp.call(_ref, k)) continue;
        v = _ref[k];
        this.locals[k] = v;
      }
      _ref2 = this.helpers;
      _fn = function(k, v) {
        return this.locals[k] = function() {
          return v(this.context, this, arguments);
        };
      };
      for (k in _ref2) {
        if (!__hasProp.call(_ref2, k)) continue;
        v = _ref2[k];
        _fn.call(this, k, v);
      }
      this.locals.postrenders = this.postrenders;
      this.locals.views = this.views;
      return this.locals.layouts = this.layouts;
    };
    MessageHandler.prototype.execute = function(client, params) {
      var k, v;
      if (this.locals == null) {
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
      for (k in params) {
        if (!__hasProp.call(params, k)) continue;
        v = params[k];
        this.locals.context[k] = v;
      }
      return this.handler(this.locals.context, this.locals);
    };
    MessageHandler.prototype.render = function(template, options) {
      var body, layout, opts, postrender, result, _ref, _ref2, _ref3;
      options != null ? options : options = {};
      (_ref = options.layout) != null ? _ref : options.layout = 'default';
      opts = options.options || {};
      (_ref2 = opts.context) != null ? _ref2 : opts.context = this.context;
      opts.context.zappa = {
        partial: this.partial
      };
      (_ref3 = opts.locals) != null ? _ref3 : opts.locals = {};
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
      this.send('render', {
        value: result
      });
      return null;
    };
    MessageHandler.prototype.partial = function(template, context) {
      template = this.views[template];
      return coffeekup.render(template, {
        context: context
      });
    };
    return MessageHandler;
  }();
  coffeescript_support = "var __slice = Array.prototype.slice;\nvar __hasProp = Object.prototype.hasOwnProperty;\nvar __bind = function(func, context) {return function(){ return func.apply(context, arguments); };};\nvar __extends = function(child, parent) { var ctor = function(){}; ctor.prototype = parent.prototype;\n  child.prototype = new ctor(); child.prototype.constructor = child;\n  if (typeof parent.extended === \"function\") parent.extended(child);\n  child.__super__ = parent.prototype;\n};";
  build_msg = function(title, data) {
    var obj;
    obj = {};
    obj[title] = data;
    return JSON.stringify(obj);
  };
  parse_msg = function(raw_msg) {
    var k, obj, v;
    obj = JSON.parse(raw_msg);
    for (k in obj) {
      if (!__hasProp.call(obj, k)) continue;
      v = obj[k];
      return {
        title: k,
        params: v
      };
    }
  };
  scoped = function(code) {
    code = String(code);
    if (code.indexOf('function') !== 0) {
      code = "function () {" + code + "}";
    }
    code = "" + coffeescript_support + " with(locals) {return (" + code + ").apply(context, args);}";
    return new Function('context', 'locals', 'args', code);
  };
  publish_api = function(from, to, methods) {
    var _fn, _i, _len, _ref, _results;
    _ref = methods.split('|');
    _fn = function(name) {
      return _results.push(typeof from[name] === 'function' ? to[name] = function() {
        return from[name].apply(from, arguments);
      } : to[name] = from[name]);
    };
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      name = _ref[_i];
      _fn(name);
    }
    return _results;
  };
  z = new Zappa();
  zappa.version = '0.1.3';
  zappa.run = function() {
    return z.run.apply(z, arguments);
  };
  zappa.run_file = function() {
    return z.run_file.apply(z, arguments);
  };
}).call(this);
