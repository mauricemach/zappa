get '/': ->
  @items = [
    {name: 'coffeescript', url: 'http://coffeescript.org'}
    {name: 'ruby', url: 'http://ruby-lang.org'}
    {name: 'python', url: 'http://python.org'}
  ]

  render 'default', options: {format: yes}

view ->
  ul ->
    for i in @items
      partial 'item', i: i

view item: ->
  li -> a href: @i.url, -> @i.name
