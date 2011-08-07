zappa = require('./support/tester') require('../src/zappa')

module.exports =
  request: ->
    t = zappa ->
      helper role: (name) ->
        if request?
          redirect '/login' unless @user.role is name

      get '/': ->
        @user = role: 'comonner'
        role 'lord'
      
    t.response {url: '/'}, {status: 302, headers: {Location: /\/login$/}}