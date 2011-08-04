(function() {
  var Tester;
  Tester = require('./tester').Tester;
  module.exports = {
    hello: function() {
      var t;
      t = new Tester(function() {
        get({
          '/string': 'string'
        });
        get({
          '/return': function() {
            return 'return';
          }
        });
        return get({
          '/send': function() {
            return send('send');
          }
        });
      });
      t.get('/string', 'string');
      t.get('/return', 'return');
      return t.get('/send', 'send');
    },
    verbs: function() {
      var t;
      t = new Tester(function() {
        post({
          '/': 'post'
        });
        put({
          '/': function() {
            return 'put';
          }
        });
        return del({
          '/': function() {
            return send('del');
          }
        });
      });
      t.response({
        method: 'post',
        url: '/'
      }, {
        body: 'post'
      });
      t.response({
        method: 'put',
        url: '/'
      }, {
        body: 'put'
      });
      return t.response({
        method: 'delete',
        url: '/'
      }, {
        body: 'del'
      });
    },
    redirect: function() {
      var t;
      t = new Tester(function() {
        return get({
          '/': function() {
            return redirect('/foo');
          }
        });
      });
      return t.response({
        url: '/'
      }, {
        status: 302,
        headers: {
          Location: /\/foo$/
        }
      });
    },
    params: function() {
      var headers, t;
      t = new Tester(function() {
        use('bodyParser');
        get({
          '/:foo': function() {
            return this.foo + this.ping;
          }
        });
        return post({
          '/:foo': function() {
            return this.foo + this.ping + this.zig;
          }
        });
      });
      t.get('/bar?ping=pong', 'barpong');
      headers = {
        'Content-Type': 'application/x-www-form-urlencoded'
      };
      return t.response({
        method: 'post',
        url: '/bar?ping=pong',
        data: 'zig=zag',
        headers: headers
      }, {
        body: 'barpongzag'
      });
    },
    static: function() {
      var t;
      t = new Tester(function() {
        return use('static');
      });
      return t.get('/foo.txt', 'bar');
    },
    view: function() {
      var t;
      t = new Tester(function() {
        get({
          '/': function() {
            return render('index', {
              layout: false
            });
          }
        });
        return view({
          index: function() {
            return h1('foo');
          }
        });
      });
      return t.get('/', '<h1>foo</h1>');
    },
    'view (file)': function() {
      var t;
      t = new Tester(function() {
        return get({
          '/': function() {
            return render('index', {
              layout: false
            });
          }
        });
      });
      return t.get('/', '<h2>CoffeeKup file template</h2>');
    },
    'view (response.render)': function() {
      var t;
      t = new Tester(function() {
        return get({
          '/': function() {
            return response.render('index', {
              layout: false
            });
          }
        });
      });
      return t.get('/', '<h2>CoffeeKup file template</h2>');
    },
    'coffee and js': function() {
      var body, headers, t;
      t = new Tester(function() {
        coffee({
          '/coffee.js': function() {
            return alert('hi');
          }
        });
        return js({
          '/js.js': 'alert(\'hi\');'
        });
      });
      headers = {
        'Content-Type': 'application/javascript'
      };
      body = ';var __slice = Array.prototype.slice;var __hasProp = Object.prototype.hasOwnProperty;var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };var __extends = function(child, parent) {  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }  function ctor() { this.constructor = child; }  ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype;  return child; };var __indexOf = Array.prototype.indexOf || function(item) {  for (var i = 0, l = this.length; i < l; i++) {    if (this[i] === item) return i;  } return -1; };(function () {\n            return alert(\'hi\');\n          })();';
      t.response({
        url: '/coffee.js'
      }, {
        headers: headers,
        body: body
      });
      body = "alert('hi');";
      return t.response({
        url: '/js.js'
      }, {
        headers: headers,
        body: body
      });
    },
    css: function() {
      var body, headers, t;
      t = new Tester(function() {
        return css({
          '/index.css': 'font-family: sans-serif;'
        });
      });
      headers = {
        'Content-Type': 'text/css'
      };
      body = 'font-family: sans-serif;';
      return t.response({
        url: '/index.css'
      }, {
        headers: headers,
        body: body
      });
    }
  };
}).call(this);
