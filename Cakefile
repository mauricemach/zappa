{spawn, exec} = require 'child_process'

{puts} = require 'sys'

task 'build', ->
  exec 'coffee -c lib/zappa.coffee', (err) ->
    puts err if err

task 'test', ->
  tests = spawn 'coffee', ['test/all.test.coffee']
  
  tests.stdout.on 'data', (data) ->
    puts 'stdout: ' + data

  tests.stderr.on 'data', (data) ->
    puts 'stderr: ' + data

  tests.on 'exit', (code) ->
    puts 'tests exited with code ' + code