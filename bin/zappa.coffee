#!/usr/bin/env coffee

zappa = require 'zappa'
coffee = require 'coffee-script'
fs = require 'fs'
path = require 'path'
OptionParser = require('coffee-script/optparse').OptionParser

usage = '''
  Usage:
    zappa [OPTIONS] path/to/app.coffee
'''

switches = [
  ['-h', '--help', 'Displays this wonderful, elucidative help message']
  ['-v', '--version', 'Shows zappa version']
  ['-p', '--port [NUMBER]', 'The port(s) for the app(s). Ex.: 8080 or 4567,80,3000']
  ['-c', '--compile', 'Compiles the app to a .js file instead of running it.']
]

compile = (coffee_path) ->
  fs.readFile coffee_path, (err, data) ->
    js = coffee.compile String(data), {'noWrap'}
    js = "require('zappa').run(function(){#{js}});"
    js_path = path.basename(coffee_path, path.extname(coffee_path)) + '.js'
    dir = path.dirname coffee_path
    js_path = path.join dir, js_path
    fs.writeFile js_path, js

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
  if options.compile then compile args[0]
  else zappa.run_file(args[0], options)
