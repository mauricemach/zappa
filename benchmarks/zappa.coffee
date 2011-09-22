require('../src/zappa') ->
  @register '.jade', @zappa.adapter 'jade'
  
  @get '/': ->
    @data.foo = 'Zappa + Jade'
    @render 'index.jade'
    
  @get '/coffeekup': ->
    @data.foo = 'Zappa + CoffeeKup'
    @render 'index.coffee'