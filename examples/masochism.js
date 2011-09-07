require('zappa')(function(c){
  c.use('static', 'bodyParser')
  
  c.get('/', function(c){
    c.data.foo = 'bar'
    c.render('index')
  })
  
  c.view({index: function(){
    h1(this.foo)
  }})
})