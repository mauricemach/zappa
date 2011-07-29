require('../src/zappa').run ->
  app.register '.jade', zappa.adapter 'jade'
  
  get '/': ->
    @foo = 'Zappa + Jade'
    render 'index.jade'
    
  get '/coffeekup': ->
    @foo = 'Zappa + CoffeeKup'
    render 'index.coffee'