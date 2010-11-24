    8888888888P        d8888 8888888b.  8888888b.     d8888          @@@    @@@        
          d88P        d88888 888   Y88b 888   Y88b   d88888        @@@@@@@@@@@@@@          
         d88P        d88P888 888    888 888    888  d88P888       @@@@@@@@@@@@@@@@           
        d88P        d88P 888 888   d88P 888   d88P d88P 888      @@@@@@@@  @@@@@@@@            
       d88P        d88P  888 8888888P"  8888888P" d88P  888      @@@            @@@             
      d88P        d88P   888 888        888      d88P   888      @@   @@@@@@@@   @@             
     d88P        d8888888888 888        888     d8888888888           @@@@@@@@                  
    d8888888888 d88P     888 888        888    d88P     888            @@@@@@                           
             

### Razor-sharp DSL for modern web apps

Zappa is a [CoffeeScript](http://coffeescript.org) DSLish layer on top of [Express](http://expressjs.com), [Socket.IO](http://socket.io) and other libs, with two obssessions in mind:

- Providing a radically focused interface for building web apps, delaying my carpal tunnel a few years.

- Exploring possibilities opened by new web technologies and the node runtime: trivialization of websockets/comet, client-server smoother integration and code sharing, server-side DOM manipulation, etc.

It is heavily influenced by [that legendary framework](http://www.sinatrarb.com) named after another awesome Frank, with also a hint of [Camping](http://camping.rubyforge.org/).

**Put on your helmet!** Zappa is barely past the proof of concept stage and things are loosely placed. Don't use it to control your nuclear launch facility just yet. All examples work though, and if you come with a spirit of adventure, you shall be rewarded.

### Hi, World

Put this in your `cuppa.coffee`:

    get '/': 'hi'

And drink it!

    $ npm install zappa
    $ zappa cuppa.coffee
    => App "default" listening on port 5678...

If you're going to restart it a thousand times per minute while developing like me, just let zappa do the job for you:

    $ zappa -w cuppa.coffee

And if you ever need to run it with the vanilla node command, we've got that covered:

    $ zappa -c cuppa.coffee
    $ node cuppa.js

### OK, but one-line string responses are mostly useless. Can you show me something closer to a real web app?

    get '*': '''
      <!DOCTYPE html>
      <html>
        <head><title>Sorry, we'll be back soon!</title></head>
        <body><h1>Sorry, we'll be back soon!</h1></body>
      </html>
    '''

### Seriously.

Right. This is what a route with a handler function looks like:

    get '/:name': ->
      "Hi, #{@name}"

Handler functions are executed within a scope that is optimized for the work of taking the input, processing it, and giving a response back, probably rendered by a template, all with minimal wiring:

    get '/:foo': ->
      @foo += '!'
      render 'index'

    view index: ->
      h1 'You said:'
      p @foo

    layout ->
      html ->
        head -> title "You said: #{@foo}"
        body -> @content

(Templating is currently [CoffeeKup](http://github.com/mauricemach/coffeekup) only, but support for arbitrary engines is under way)

All your input variables are available at '@/this'. This context is also shared with your views (along with any vars you created there yourself).

The API to deal with the request and response is available in the form of locals. Those are: request/response/next (directly from express), send/redirect/session/cookies (shortcuts), params (reference to @), render (different implementation from express' response.render at the moment) and app (see bi-directional messaging below).

If you return a string, it will automatically be sent as the response.

### Fine. But this is node! What about some async?

Both examples below will produce `bar?!` if you request `/bar`:

    get '/:foo': ->
      @foo += '?'
      actbusy =>
        @foo += '!'
        render 'index'

Or if you can't / don't want to use the fat arrow to bind "@/this":

    get '/:foo': ->
      @foo += '?'
      actbusy ->
        params.foo += '!'
        render 'index'

### Let me guess. You can also post/put/del, use regexes, routes are matched first to last, all like any self-respecting sinatra clone.

Exactly. Actually, when it comes to HTTP zappa hands over all the serious work to express, so there are no big surprises here:

    get '/': 'got'
    post '/': 'posted'
    put '/': 'put'
    del '/': 'deleted'
    get '*': 'any url'

### Route combo

The routing functions accept an object where the keys are the paths for the routes, and the values are the responses. This means we can define multiple routes in one go:

    get '/foo': 'bar', '/ping': 'pong', '/zig': 'zag'

Better yet:

    get
      '/foo': 'bar'
      '/ping': 'pong'
      '/zig': 'zag'

You can also use the syntax where the first param is the path, and the second the response. This is mostly to allow for regexes:

    get '/foo', 'bar'
    get /^\/ws-(.*)/, ->
      'bloatware-' + params[0]

### Bi-directional messaging (WebSockets/Comet)

But the web is not just about HTTP requests anymore. WebSockets are soon to become available on all major browsers but IE. For this sucker and legacy browsers, there's a collection of hacks that are ugly but work, and thanks to Socket.IO, we don't even have to care.

Zappa pushes this trivialization a bit further by removing some of the boilerplate, and providing some integration. The goal is to make messaging feel more like a first-class citizen along with request handling, readily available, instead of an exotic feature you bolt on your app.

All you have to do to handle bi-directional messaging in your apps is declare the handlers, side by side with your HTTP ones:

    get '/chat': ->
      render 'chat'

    get '/counter': ->
      "Total messages so far: #{app.counter}"

    at connection: ->
      app.counter ?= 0
      send 'welcome', time: new Date()
      broadcast "#{id} connected"

    at disconnection: ->
      broadcast "#{id} is gone!"

    msg said: ->
      app.counter++
      broadcast 'said', id: id, text: @text

    msg afk: ->
      broadcast 'afk', id: id

When your app starts, if you defined one of those handlers, zappa will automatically require Socket.IO and fire it up. It will not take up a dedicated port, since Socket.IO can attach itself to the HTTP server and intercept websocket/comet related messages.

Zappa uses a minimal protocol to enable handler wiring. If you send this message from the client:

    {said: {text: "hi"}}

It will automatically JSON.parse it, and call the handler named `said`, putting the value of `text` in its context.

Conversely, when you call `send 'welcome', online: 7`, the following string will be sent to the client:

    {welcome: {online: "7"}}

Message and request handlers are designed to behave as similarly as possible. The context (@/this) receives the input and is shared with templates, and there are local variables readily available to deal with the task at hand. In this case, they are: client, id, send, broadcast, render, and app.

Both types of handlers have access to the `app` variable, which is persistent throughout the application lifecycle. You can store temporary, app-level data here to provide some integration between your app's two "sides", like in the message counter example.

### Client-side code embedding

With `client` you can define a route `/name.js` that will respond with your CoffeeScript code in JS form, and the correct content-type set. No compilation involved, since we already have you function's string representation from the runtime.

    get '/': -> render 'index'

    client index: ->
      alert 'hullo'

    view index: ->
      h1 'Client embedding example'

    layout ->
      html ->
        head -> title 'bla'
        script src: '/index.js'
      body -> @content

This is the first of a series of planned features to ease client/server integration. Next on the list is function/class sharing between your handlers and your clients.

### Scope and `def`

In order to gain automatic access to framework locals, request and message handlers lose automatic access to their parent scope. To make things available to them though, you can use `def`:

    foo = 'bar'
    def ping: 'pong'
    def zig: -> 'zag'

    get '/': ->
      foo # undefined
      ping # 'pong'
      zig() # 'zag'

### Using `using`

Same as `def eco: require 'eco'`:

    using 'eco'

    get '/': ->
      typeof eco.render # function

You can also do many in a row:

    using 'fs', 'path', 'util'

### Helpful `helper`

Helpers are just like defs, except they are modified to have access to the same context (@/this) and framework locals as whatever called them (request or message handlers).

    helper role: (name) ->
      if request?
        redirect '/login' unless @user.role is name
      else
        client.disconnect() unless @user.role is name

    get '/gm': ->
      role 'gm'
      # see stuff

    msg kill: ->
      role 'gm'
      # kill stuff

### Post-rendering with server-side jQuery

Rendering things linearly is often the approach that makes more sense, but sometimes DOM manipulation can avoid loads of repetition. The best DOM libraries in the world are in javascript, and thanks to the work of Elijah Insua with [jsdom](http://jsdom.org/), you can use some with node too.

Zappa makes it trivial to post-process your rendered templates by manipulating them with jQuery:

    postrender plans: ->
      $('.staff').remove() if @user.plan isnt 'staff'
      $('div.' + @user.plan).addClass 'highlighted'

    get '/postrender': ->
      @user = plan: 'staff'
      render 'index', apply: 'plans'

It currently works with your inner templates only though, not layouts.

### App combo

There are no "run" blocking calls in node, so you can have multiple apps listening to different ports on the same process. To do that with zappa, just name your apps:

    get '/': 'blog'

    app 'chat'
    get '/': 'chat'

    app 'wiki'
    get '/': 'wiki'

    $ zappa apps.coffee
    => App "default" started on port 5678
    => App "chat" started on port 5679
    => App "wiki" started on port 5680

To specify the ports:

    $ zappa -p 3000,4567,8080 apps.coffee

### Splitting up

If your single file of doom is becoming unwieldy, you can split it up with whatever organization is better suited to the project(s) at hand:

    include 'model.coffee'
    include 'controllers/http.coffee'
    include 'controllers/websockets.coffee'
    include 'controllers/client.coffee'
    include 'controllers/common.coffee'
    include 'views.coffee'

Or by subject:

    include 'users.coffee'
    include 'widgets.coffee'
    include 'gadgets.coffee'
    include 'funzos.coffee'

### Static files

If there's a `./public` dir on the same level as your app's main file, static files will be automatically served from there. 

## Whew!

That's it for now. Big thanks to all behind the libs that are making this little experiment possible. Special thanks to Jeremy Ashkenas for CoffeeScript, the "little" language is simply amazing and incredibly flexible. To Blake Mizerany for Sinatra, the framework that made me redefine simple. To why the lucky stiff, that made me redefine hacking. And finally to Frank Zappa, for the spirit of nonconformity and experimentation that inspires me to push forward. No to mention providing the soundtrack.

"Why do you necessarily have to be wrong just because a few million people think you are?" - FZ
