zappa = require './zappa'
coffee = require 'coffee-script'
fs = require 'fs'
path = require 'path'
puts = console.log
{inspect} = require 'util'
{spawn} = require 'child_process'
{OptionParser} = require 'coffee-script/lib/optparse'
child = null
file = null
watching = []

argv = process.argv[2..]
options = null

usage = '''
  Usage:
    zappa [OPTIONS] path/to/app.coffee
'''

switches = [
  ['-h', '--help', 'Displays this wonderful, elucidative help message']
  ['-v', '--version', 'Shows zappa version']
  ['-p', '--port [NUMBER]', 'The port(s) the app(s) will listen on. Ex.: 8080 or 4567,80,3000']
  ['-n', '--hostname [STRING]', 'If omitted, will accept connections to any ipv4 address (INADDR_ANY)']
  ['-c', '--compile', 'Compiles the app(s) to a .js file instead of running them.']
  ['-w', '--watch', 'Keeps watching the file and restarts the app when it changes.']
]

compile = (coffee_path, callback) ->
  fs.readFile coffee_path, (err, data) ->
    if err then callback(err)
    else
      js = coffee.compile String(data), bare: yes
      js = "require('zappa').run(function(){#{js}});"
      js_path = path.basename(coffee_path, path.extname(coffee_path)) + '.js'
      dir = path.dirname coffee_path
      js_path = path.join dir, js_path
      fs.writeFile js_path, js, (err) ->
        if err then callback(err)
        else callback()

remove_watch_option = ->
  i = argv.indexOf('-w')
  argv.splice(i, 1) if i > -1
  i = argv.indexOf('--watch')
  argv.splice(i, 1) if i > -1

spawn_child = ->
  child = spawn 'zappa', argv
  child.stdout.on 'data', (data) ->
    data = String(data)
    if data.match /^Included file \".*\.coffee\"/
      included = data.match(/^Included file \"(.*\.coffee)\"/)[1]
      watch path.resolve included unless included in watching
      watching.push included
    puts data
  child.stderr.on 'data', (data) -> puts String(data)

watch = (file) ->
  fs.watchFile file, {persistent: true, interval: 500}, (curr, prev) ->
    return if curr.size is prev.size and curr.mtime.getTime() is prev.mtime.getTime()
    puts 'Changes detected, reloading...'
    child.kill() # Infanticide!
    spawn_child()

@run = ->
  parser = new OptionParser switches, usage
  options = parser.parse argv
  args = options.arguments
  delete options.arguments

  if options.port
    options.port = if options.port.match /,/ then options.port.split ',' else [options.port]
    for i, p of options.port
      options.port[i] = parseInt(p)

  if args.length is 0
    puts parser.help() if options.help or argv.length is 0
    puts zappa.version if options.version
    process.exit()
  else
    file = args[0]
    
    path.exists file, (exists) ->
      if not exists
        puts "\"#{file}\" not found."
        process.exit -1
      
      if options.compile
        compile file, (err) ->
          if err then puts err; process.exit -1
          else process.exit()
      else
        if options.watch
          remove_watch_option()
          spawn_child()
          watch file
        else
          zappa.run_file file, options
