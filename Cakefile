{spawn, exec} = require 'child_process'

log = console.log

task 'build', ->
  exec 'coffee -o lib -c src/*.coffee', (err) ->
    log err if err
    
task 'benchmark', ->
  exec 'cd benchmarks && ./run', (err, stdout, stderr) ->
    if err then log stderr
    else log stdout