#!/usr/bin/env coffee

zappa = require 'zappa'
fs = require 'fs'
exec = require('child_process').exec
OptionParser = require('coffee-script/optparse').OptionParser

usage = '''
  Usage:
    zappa [OPTIONS] path/to/app.coffee
'''

switches = [
  ['-h', '--help', 'Displays this wonderful, elucidative help message']
  ['-v', '--version', 'Shows zappa version']
  ['-p', '--port [NUMBER]', 'The port(s) for the app(s). Ex.: 8080 or 4567,80,3000']
]

parser = new OptionParser switches, usage
options = parser.parse process.argv
args = options.arguments
delete options.arguments

puts parser.help() if options.help or process.argv.length is 0
puts zappa.version if options.version

if args.length > 0
  zappa.run(fs.realpathSync(args[0]), options)
