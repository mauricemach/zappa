#!/usr/bin/env coffee

zappa = require 'zappa'

fs = require 'fs'
exec = require('child_process').exec

usage = '''
  Usage:
    zappa path/to/app.coffee

  Commands:
    -h, --help: displays this wonderful, elucidative help message
    -v, --version: shows zappa version
'''

args = process.argv

switch args[0]
  when undefined, null
    puts usage
  when '-h', '--help'
    puts usage
  when '-v', '--version'
    puts zappa.version
  else
    zappa.run(fs.realpathSync args[0])
