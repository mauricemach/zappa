require('zappa')(function(){
  use('static', 'bodyParser')
  
  get('/', function(){
    this.foo = 'bar'
    render('index')
  })
  
  view({index: function(){
    h1(this.foo)
  }})
})