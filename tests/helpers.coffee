zappa = require '../src/zappa'
port = 15100

@tests =
  http: (t) ->
    t.expect 1, 2
    t.wait 3000
    
    zapp = zappa port++, ->
      helper role: (name) ->
        if request?
          redirect '/login' unless @user.role is name

      get '/': ->
        @user = role: 'comonner'
        role 'lord'
        
    c = t.client(zapp.app)
    
    c.get '/', (err, res) ->
      t.equal 1, res.statusCode, 302
      t.ok 2, res.headers.location.match /\/login$/