**v0.1.5** (2010-05-06):

  - Compatible with npm 1.x.

**v0.1.4** (2010-01-05):

  - Updated to CoffeeScript 1.0.0 and node 0.2.6/0.3.3.
  - Soda tests by Nicholas Kinsey.
  - `broadcast` passing along optional `except` param to socket.io.
  - Empty app files now start a default "blank" app, serving files at /public.
  - `zappa -n/--hostname` to listen on a specific hostname or IP.
  - Made defs available to postrenders' scope.
  - Bug fixes.

**v0.1.3** (2010-11-13):

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
