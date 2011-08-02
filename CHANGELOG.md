**v0.2.0beta** (2011-07-xx):

  - Complete rewrite, the main idea/api/capabilities are mostly the same, but implemented and used in a way
    more harmonized with the node ecosystem.
  
  - Fixed performance issues, now negligible overhead over express. Gone with the `with` keyword.

  - Scraped the `zappa` command. One additional `require` line and now zappa apps can be run directly with
    standard `coffee` and `node` commands, compiled with `coffee`, reloaded with `runjs`/`nodemon` etc,
    deployed with `forever` or to services such as [nodester](http://nodester.com) and [no.de](http://no.de)
    with no special steps required.

  - New `app` and `io` variables at all scopes, providing direct access to express and socket.io.

  - Now using the rendering system from express, with all the features it supports (arbitrary engines,
    partials, etc), while retaining the ability to define templates in-file with the `view` function and
    pass variables to the template through `@/this`. 

  - The `include` function now is implemented through the standard `require`. Files `include`'d should
    just add a `module.exports = ->` line.

  - Scraped zappa's socket "protocol", using the new socket.io 0.7.x custom events which work in the same way.
    
  - Optional client-side zappa with socket.io and sammy.js for routes.
  
  - Added `shared '/foo.js': ->`, allows sharing `helper`s and `def`s between server and client side code.

**v0.1.5** (2011-05-06):

  - Reworked packaging for npm 1.x.

**v0.1.4** (2011-01-05):

  - Updated to CoffeeScript 1.0.0 and node 0.2.6/0.3.3.
  - Soda tests by Nicholas Kinsey.
  - `broadcast` passing along optional `except` param to socket.io.
  - Empty app files now start a default "blank" app, serving files at /public.
  - `zappa -n/--hostname` to listen on a specific hostname or IP.
  - Made defs available to postrenders' scope.
  - Bug fixes.

**v0.1.3** (2010-11-24):

  - Updated to CoffeeScript 0.9.5 and node 0.2.5/0.3.1.
  - Partials support.
  - Compilation to .js file with `zappa -c`.
  - Auto-restarting on changes with `zappa -w`.

**v0.1.2** (2010-11-13):

  - Multiple `using`'s: `using 'foo', 'bar', 'etc'`.
  - Added `layout: no` option to `render`.
  - Added `require` at the root level and `send` at the request level (shortcut to `request.send`).
  - bodyDecoder, cookieDecoder and session middleware by default. Configs to turn them off will follow.
  - Using new jQuery (1.4.3) npm package instead of jsdom directly.
  - Using Socket.IO 0.6.0 (great improvements over the previous version).

**v0.1.1** (2010-10-22):

**v0.1.0** (2010-10-21):
