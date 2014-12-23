App.IndexRoute = App.PaginatedBaseRoute.extend
  init: ->
    @_super('item')

  limit: 2
  #model: ->
    #@store.filter('item', { top: 100 })
    #@store.find('item', { q:"tree", limit: 3, offset: 0})
