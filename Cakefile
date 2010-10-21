exec = require('child_process').exec

task 'build', ->
  exec 'coffee -c lib/zappa.coffee', (err) ->
    puts err if err
