{spawn, exec} = require 'child_process'

{puts} = console.log

task 'build', ->
  exec 'coffee -o lib -c src/*.coffee', (err) ->
    puts err if err

task 'test', ->
  tests = spawn 'coffee', ['test/all.test.coffee']
  
  tests.stdout.on 'data', (data) ->
    puts 'stdout: ' + data

  tests.stderr.on 'data', (data) ->
    puts 'stderr: ' + data

  tests.on 'exit', (code) ->
    puts 'tests exited with code ' + code
