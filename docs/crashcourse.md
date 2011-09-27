---
layout: default
title: Crash Course
permalink: /crashcourse/index.html
---

# {{page.title}}

Let's start with the classic:

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

Or to follow the bleeding edge:

    git clone git@github.com:mauricemach/zappa.git && cd zappa
    cake build
    cake vendor
    npm link

Then in your project:

    npm link zappa

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