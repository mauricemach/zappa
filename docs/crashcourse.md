---
layout: default
title: Crash Course
permalink: /crashcourse/index.html
---

# {{page.title}}

Let's start with the classic:

## Hi, World

Get a `cuppa.coffee`:

{% highlight coffeescript %}
require('zappa') ->
  get '/': 'hi'
{% endhighlight %}

And give your foot a push:

    $ npm install zappa
    $ coffee cuppa.coffee    
       info  - socket.io started
    Express server listening on port 3000 in development mode
    Zappa 0.2.0beta orchestrating the show

## Nice, but one-line string responses are mostly useless. Can you show me something closer to a real web app?

{% highlight coffeescript %}
get '*': '''
  <!DOCTYPE html>
  <html>
    <head><title>Sorry, we'll be back soon!</title></head>
    <body><h1>Sorry, we'll be back soon!</h1></body>
  </html>
'''
{% endhighlight %}

## Seriously.

Right. This is what a basic route with a handler function looks like:

{% highlight coffeescript %}
get '/:name': ->
  "Hi, #{@name}"
{% endhighlight %}

If you return a string, it will automatically be sent as the response.

Now for a more typical scenario:

{% highlight coffeescript %}
get '/users/:id': ->
  User.findById @id, (@err, @user) =>
    render 'user'

view user: ->
  if @err
    @title = 'Error'
    p "Something terrible happened: #{@err}."
  else
    @title = "#{@user.name}'s Home"
    p "Hullo, #{@user.name}!"

view layout: ->
  html ->
    head -> title @title
    body ->
      h1 @title
      @body
{% endhighlight %}

Handler functions are executed within a specially crafted scope that is optimized for the typical scenario of taking the input, processing it, rendering a view with this data and sending a response, all with *minimal wiring*.

You have certain local variables automatically available such as `request`, `response` and `next` (straight from Express). You also have shortcuts such as `send`, `redirect` and `render`.

Besides being able to read your input through the standard API (ex.: `request.query.foo` and friends), you also have access to a merged collection of them, as `@foo` and the alias `params.foo`.

All variables at `@`/`params` (from input or put there by you) are automatically made available to templates as `params.foo` (in CoffeeKup, `@params.foo`).

In addition, if you're using the *zappa view adapter* (as is the case by default, with CoffeeKup), they're also made available at the template's "root namespace" (`foo` or CoffeeKup's `@foo`).

Since in express templating data is usually mixed up with framework locals and template options, the adapter will only put variables in the template root if there isn't a variable there with the same name already, *and* the name is not blacklisted.

To use this feature with other templating engines:

{% highlight coffeescript %}
blacklist = ['scope', 'self', 'locals', 'filename',
  'debug', 'compiler', 'compileDebug', 'inline']
app.register '.jade', zappa.adapter 'jade', blacklist
{% endhighlight %}

To disable it on default zappa:

{% highlight coffeescript %}
app.register '.coffee', require('coffeekup').adapters.express
{% endhighlight %}

## Fine. But this is node! What about some async?

Both examples below will produce `bar?!` if you request `/bar`:

{% highlight coffeescript %}
get '/:foo': ->
  @foo += '?'
  
  sleep 3, =>
    @foo += '!'
    render 'index'
{% endhighlight %}

Or if you can't / don't want to use the fat arrow to bind `@`:

{% highlight coffeescript %}
get '/:foo': ->
  params.foo += '?'
  
  sleep 3, ->
    params.foo += '!'
    render 'index'
{% endhighlight %}

## Let me guess. You can also post/put/del, use regexes, routes are matched first to last, all like any self-respecting sinatra clone.

Exactly. Actually, when it comes to HTTP zappa hands over all the serious work to Express, so there are no big surprises here:

{% highlight coffeescript %}
get '/': 'got'
post '/': 'posted'
put '/': 'put'
del '/': 'deleted'
get '*': 'any url'
{% endhighlight %}

## Route combo

The routing functions accept an object where each key is a route path, and each values the response. This means we can define multiple routes in one go:

{% highlight coffeescript %}
get '/foo': 'bar', '/ping': 'pong', '/zig': 'zag'
{% endhighlight %}

Better yet:

{% highlight coffeescript %}
get
  '/foo': 'bar'
  '/ping': 'pong'
  '/zig': 'zag'
{% endhighlight %}

You can also use the default syntax where the first param is the path, and the second the response. This is mostly to allow for regexes:

{% highlight coffeescript %}
get '/foo', 'bar'
get /^\/ws-(.*)/, ->
  'bloatware-' + params[0]
{% endhighlight %}

## Bi-directional events (WebSockets/Comet)

But the web is not just about HTTP requests anymore. WebSockets are soon to become available on all major browsers but IE. For this sucker and legacy browsers, there's a collection of ugly hacks that work (comet), and thanks to Socket.IO, we don't even have to care.

Zappa pushes this trivialization a bit further by removing some of the boilerplate, and providing some integration. The goal is to make event handling feel more like a first-class citizen along with request handling, readily available, instead of an exotic feature you bolt on your app.

All you have to do to handle bi-directional events in your apps is declare the handlers, side by side with your HTTP ones:

{% highlight coffeescript %}
get '/chat': ->
  render 'chat'

get '/counter': ->
  "Total messages so far: #{app.counter}"

at connection: ->
  app.counter ?= 0
  emit 'welcome', time: new Date()
  broadcast "#{id} connected"

at disconnect: ->
  broadcast "#{id} is gone!"

at said: ->
  app.counter++
  broadcast 'said', {id, @text}

at afk: ->
  broadcast 'afk', {id}
{% endhighlight %}

When your app starts, if you defined one of those handlers, zappa will automatically require Socket.IO and fire it up. It will not take up a dedicated port, since Socket.IO can attach itself to the HTTP server and intercept WebSockets/comet traffic.

Event and request handlers are designed to behave as similarly as possible. There are locals for the standard API (`io`, `socket`), shortcuts (`emit`, `broadcast`) and input variables are also available at `@`.

## But what about the client-side?

That's an interesting question! Let's start with the basics.

First there's `coffee` with which you can define a route `/file.js`, that will respond with your CoffeeScript code in JS form, and the correct content-type set. No compilation involved, since we already have you function's string representation from the runtime.

{% highlight coffeescript %}
get '/': -> render 'index'

coffee '/index.js': ->
  alert 'hullo'

view index: ->
  h1 'Client embedding example'

view layout: ->
  html ->
    head -> title 'bla'
    script src: '/index.js'
  body @body
{% endhighlight %}

On a step further, you have `client`, which gives you access to a matching zappa client-side API:

{% highlight coffeescript %}
enable 'serve jquery', 'serve sammy'

get '/': ->
  render 'index', layout: no

at connection: ->
  emit 'server time', time: new Date()

client '/index.js': ->
  def sum: (a, b) -> a + b

  get '#/': ->
    alert 'index'
  
  at 'server time': ->
    alert "Server time: #{@time}"
    
  connect 'http://localhost'
    
view index: ->
  doctype 5
  html ->
    head ->
      title 'Client-side zappa'
      script src: '/socket.io/socket.io.js'
      script src: '/zappa/jquery.js'
      script src: '/zappa/sammy.js'
      script src: '/zappa/zappa.js'
      script src: '/index.js'
    body ''
{% endhighlight %}
        
Finally, there's also `shared`. Certain zappa "keywords" work exactly the same on the server and client side. Guess what? If you define them inside a `shared` block, they're available at both environments!

{% highlight coffeescript %}
shared '/index.js': ->
  def sum: (a, b) -> a + b

  helper role: (name) ->
    unless @user.role is name
      if request? then redirect '/login'
      else if window? then alert "This is not the page you're looking for."
      else if socket? then client.disconnect()

get '/admin': ->
  role 'admin'
  # admin stuff
  
at 'delete everything': ->
  role 'admin'
  
client '/index.js': ->
  get '#/admin': ->
    role 'admin'
    # admin stuff
{% endhighlight %}

## Scope and `def`

In order to gain all these specialized scopes, we lose closures.

To make things available at the root scope:

{% highlight coffeescript %}
foo = 'bar'
require('zappa') {foo}, ->
  console.log foo   # 'bar'
{% endhighlight %}

To make things available to handlers, use `def`:

{% highlight coffeescript %}
foo = 'bar'
def ping: 'pong'
def zig: -> 'zag'

get '/': ->
  foo   # undefined
  ping  # 'pong'
  zig() # 'zag'
{% endhighlight %}

## But `def foo: require 'foo'` is stupid repetition! I'm lazy!

Luckily for you, so am I. Meet `requiring`, `require`'s less patient brother.

{% highlight coffeescript %}
requiring 'fs', 'path', 'util'

get '/': ->
  console.log fs, path, util
{% endhighlight %}

## Santa's little `helper`s

Helpers are just like defs, except they are modified to have access to the same context (@/this) and framework locals as whatever called them (request or event handlers).

{% highlight coffeescript %}
helper role: (name) ->
  if request?
    redirect '/login' unless @user.role is name
  else
    client.disconnect() unless @user.role is name

get '/gm': ->
  role 'gm'
  # see stuff

at kill: ->
  role 'gm'
  # kill stuff
{% endhighlight %}

## Post-rendering with server-side jQuery

Rendering things linearly is often the approach that makes more sense, but sometimes DOM manipulation can avoid loads of repetition. The best DOM libraries in the world are in javascript, and thanks to the work of Elijah Insua with [jsdom](http://jsdom.org/), you can use some with node too.

Zappa makes it trivial to post-process your rendered templates by manipulating them with jQuery:

{% highlight coffeescript %}
postrender plans: ->
  $('.staff').remove() if @user.plan isnt 'staff'
  $('div.' + @user.plan).addClass 'highlighted'

get '/postrender': ->
  @user = plan: 'staff'
  render 'index', postrender: 'plans'
{% endhighlight %}

## App combo

Node.js servers don't block when calling `listen`, so you can run many apps in the same process:

{% highlight coffeescript %}
zappa = require 'zappa'

zappa 8001, -> get '/': 'blog'
zappa 8002, -> get '/': 'chat'
zappa 8003, -> get '/': 'wiki'

$ coffee apps.coffee
{% endhighlight %}
    
You can also take advantage of Express/Connect vhost middleware:

{% highlight coffeescript %}
zappa = require 'zappa'

chat = zappa.app -> get '/': 'chat'
blog = zappa.app -> get '/': 'blog'

zappa 80, {chat, blog}, ->
  use express.vhost 'chat.com', chat
  use express.vhost 'blog.com', blog
{% endhighlight %}

## Splitting it up

If your single file of doom is becoming unwieldy, you can split it up based on whatever organization suits you better:

{% highlight coffeescript %}
include 'model'
include 'controllers/http'
include 'controllers/websockets'
include 'controllers/client'
include 'controllers/common'
include 'views'
{% endhighlight %}

Or by subject:

{% highlight coffeescript %}
include 'users'
include 'widgets'
include 'gadgets'
include 'funzos'
{% endhighlight %}
    
The files to be included just have to export an `include` function:

{% highlight coffeescript %}
# Could be `module.exports.include` as well.
@include = ->
  get '/': 'This is a route inside an included file.'
{% endhighlight %}

## Connect(ing) middleware

You can specify your middleware through the standard `app.use`, or zappa's shortcut `use`. The latter can be used in a number of additional ways:

- It accepts many params in a row. Ex.:

        use express.bodyParser(), app.router, express.cookies()

- It accepts strings as parameters. This is syntactic sugar to the equivalent express middleware with no arguments. Ex.:

        use 'bodyParser', app.router, 'cookies'

- You can also specify parameters by using objects. Ex.:

        use 'bodyParser', static: __dirname + '/public', session: {secret: 'fnord'}, 'cookies'

- Finally, when using strings and objects, zappa will intercept some specific middleware and add behaviour, usually default parameters. Ex.:

        use 'static'
        
        # Syntactic sugar for:
        app.use express.static(__dirname + '/public')