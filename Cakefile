{spawn, exec} = require 'child_process'

{puts} = console.log

task 'build', ->
  exec 'coffee -o lib -c src/*.coffee', (err) ->
    puts err if err