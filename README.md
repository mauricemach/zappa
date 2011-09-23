    8888888888P        d8888 8888888b.  8888888b.     d8888          @@@    @@@ 
          d88P        d88888 888   Y88b 888   Y88b   d88888        @@@@@@@@@@@@@@
         d88P        d88P888 888    888 888    888  d88P888       @@@@@@@@@@@@@@@@
        d88P        d88P 888 888   d88P 888   d88P d88P 888      @@@@@@@@  @@@@@@@@
       d88P        d88P  888 8888888P"  8888888P" d88P  888      @@@            @@@
      d88P        d88P   888 888        888      d88P   888      @@   @@@@@@@@   @@
     d88P        d8888888888 888        888     d8888888888           @@@@@@@@    
    d8888888888 d88P     888 888        888    d88P     888            @@@@@@     

### Node development for the lazy

Zappa is a [coffeescript](http://coffeescript.org)-optimized interface to [express](http://expressjs.com) and [socket.io](http://socket.io) that makes this:

```coffeescript
require('zappa') ->
  Gizmo = require './model/gizmo'
  
  @use 'bodyParser', 'methodOverride', @app.router, 'static'

  @configure
    development: => @use errorHandler: {dumpExceptions: on}
    production: => @use 'errorHandler'

  @get '/': -> @render 'index'
  
  @get '/gizmos/:id': ->
    Gizmo.findById @query.id, (err, gizmo) =>
      @render index: {err, gizmo}

  @on connection: ->
    @emit welcome: {time: new Date()}

  @on shout: ->
    @broadcast shout: {@id, text: @data.text}
```

Equivalent to this:

```coffeescript
app = require('express').createServer()
io = require('socket.io').listen(app)

Gizmo = require './model/gizmo'

app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use express.static __dirname + '/public'

app.configure 'development', ->
  app.use express.errorHandler dumpExceptions: on

app.configure 'production', ->
  app.use express.errorHandler()

app.get '/', (req, res) -> res.render 'index'

app.get '/gizmos/:id', (req, res) ->
  Gizmo.findOne req.params.id, (err, gizmo) ->
    res.render 'index', {err, gizmo}

io.sockets.on 'connection', (socket) ->
  socket.emit 'welcome', time: new Date()

  socket.on 'shout', (data) ->
    socket.broadcast.emit 'shout',
      id: socket.id, text: data.text

app.listen 3000
```

### Overview

  - DRYer shortcuts for everything. Direct access to the underlying APIs to fallback to when needed.
  - Socket.io integration, out of the box.
  - Matching client-side API.
  - Client-server code sharing.
  - Inline views, css/stylus, js/coffee.
  - Postrender.
  - Default layout.
  - Serve jQuery.

### Hi, World

Get a `cuppa.coffee`:

    require('zappa') ->
      @get '/': 'hi'

And give your foot a push:

    $ npm install zappa
    $ coffee cuppa.coffee    
       info  - socket.io started
    Express server listening on port 3000 in development mode
    Zappa 0.3.0 orchestrating the show

### ...

...

### Santa's little `helper`s

Helpers are functions with automatic access to the same context (`this`/`@`) as whatever called them (request or event handlers, client or server-side).

    @helper role: (name) ->
      if @request?
        @redirect '/login' unless @user.role is name
      else
        @client.disconnect() unless @user.role is name

    @get '/gm': ->
      @role 'gm'
      # see stuff

    @on kill: ->
      @role 'gm'
      # kill stuff

### Post-rendering with server-side jQuery

Rendering things linearly is often the approach that makes more sense, but sometimes DOM manipulation can avoid loads of repetition. The best DOM libraries in the world are in javascript, and thanks to the work of Elijah Insua with [jsdom](http://jsdom.org/), you can use some with node too.

Zappa makes it trivial to post-process your rendered templates by manipulating them with jQuery:

    @postrender plans: ($) ->
      $('.staff').remove() if @user.plan isnt 'staff'
      $('div.' + @user.plan).addClass 'highlighted'

    @get '/postrender': ->
      @user = plan: 'staff'
      @render 'index', postrender: 'plans'

### Splitting it up

If your single file of doom is becoming unwieldy, you can split it up based on whatever organization suits you better:

    @include 'model'
    @include 'controllers/http'
    @include 'controllers/websockets'
    @include 'controllers/client'
    @include 'controllers/common'
    @include 'views'

Or by subject:

    @include 'users'
    @include 'widgets'
    @include 'gadgets'
    @include 'funzos'
    
The files to be included just have to export an `include` function:

    module.exports.include = ->
      @get '/': 'This is a route inside an included file.'

### Connect(ing) middleware

You can specify your middleware through the standard `app.use`, or zappa's shortcut `use`. The latter can be used in a number of additional ways:

It accepts many params in a row. Ex.:

    @use @express.bodyParser(), @app.router, @express.cookies()

It accepts strings as parameters. This is syntactic sugar to the equivalent express middleware with no arguments. Ex.:

    @use 'bodyParser', @app.router, 'cookies'

You can also specify parameters by using objects. Ex.:

    @use 'bodyParser', static: __dirname + '/public', session: {secret: 'fnord'}, 'cookies'

Finally, when using strings and objects, zappa will intercept some specific middleware and add behaviour, usually default parameters. Ex.:

    @use 'static'
    
    # Syntactic sugar for:
    @app.use @express.static(__dirname + '/public')

## Resources

- [API reference](https://github.com/mauricemach/zappa/blob/master/docs/reference.md)

- [Mailing list](https://groups.google.com/group/zappajs)

- [Issues](https://github.com/mauricemach/zappa/issues)

- [Hosting Zappa 0.2.x on Heroku](http://blog.superbigtree.com/blog/2011/08/19/hosting-zappa-0-2-x-on-heroku/)

- **IRC**: #zappajs on irc.freenode.net

## Thanks loads

To all people behind the excellent libs that made this little project possible, more specifically: 

- Jeremy Ashkenas for CoffeeScript, the "little" language is nothing short of revolutionary to me.

- TJ Holowaychuk for the robust and flexible cornerstone that's Express.

- Guillermo Rauch for solving (as far as I'm concerned) the comet problem once and for all.

- Ryan Dahl for Node.js, without which nothing of this would be possible.

Also:

- Blake Mizerany for Sinatra, the framework that made me redefine simple.

- why the lucky stiff, for making me redefine hacking.

- And last but not least Frank Zappa, for the spirit of nonconformity and experimentation that inspires me to push forward. Not to mention providing the soundtrack.

"Why do you necessarily have to be wrong just because a few million people think you are?" - FZ