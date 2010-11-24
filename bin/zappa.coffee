#!/usr/bin/env coffee

zappa = require 'zappa'
coffee = require 'coffee-script'
fs = require 'fs'
path = require 'path'
puts = console.log
spawn = require('child_process').spawn
OptionParser = require('coffee-script/optparse').OptionParser
child = null
file = null
watching = []

usage = '''
  Usage:
    zappa [OPTIONS] path/to/app.coffee
'''

switches = [
  ['-h', '--help', 'Displays this wonderful, elucidative help message']
  ['-v', '--version', 'Shows zappa version']
  ['-p', '--port [NUMBER]', 'The port(s) for the app(s). Ex.: 8080 or 4567,80,3000']
  ['-c', '--compile', 'Compiles the app(s) to a .js file instead of running them.']
  ['-w', '--watch', 'Keeps watching the file and restarts the app when it changes.']
]

compile = (coffee_path) ->
  fs.readFile coffee_path, (err, data) ->
    js = coffee.compile String(data), bare: yes
    js = "require('zappa').run(function(){#{js}});"
    js_path = path.basename(coffee_path, path.extname(coffee_path)) + '.js'
    dir = path.dirname coffee_path
    js_path = path.join dir, js_path
    fs.writeFile js_path, js

remove_watch_option = ->
  process.argv.splice(process.argv.indexOf('-w'), 1).splice(process.argv.indexOf('--watch'), 1)

spawn_child = ->
  child = spawn 'zappa', process.argv
  child.stdout.on 'data', (data) ->
    data = String(data)
    if data.match /^Included file \".*\.coffee\"/
      included = data.match(/^Included file \"(.*\.coffee)\"/)[1]
      watch path.join(path.dirname(file), included) unless included in watching
      watching.push included
    puts data
  child.stderr.on 'data', (data) -> puts data

watch = (file) ->
  fs.watchFile file, {persistent: true, interval: 500}, (curr, prev) ->
    return if curr.size is prev.size and curr.mtime.getTime() is prev.mtime.getTime()
    puts 'Changes detected, reloading...'
    child.kill() # Infanticide!
    spawn_child()

parser = new OptionParser switches, usage
options = parser.parse process.argv
args = options.arguments
delete options.arguments

if options.port
  options.port = if options.port.match /,/ then options.port.split ',' else [options.port]
  for i, p of options.port
    options.port[i] = parseInt(p)

puts parser.help() if options.help or process.argv.length is 0
puts zappa.version if options.version

if args.length > 0
  file = args[0]
  if options.compile then compile file
  else
    if options.watch
      remove_watch_option()
      spawn_child()
      watch file
    else
      zappa.run_file file, options
