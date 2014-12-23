App.SearchRoute = Ember.Route.extend
  model: (params)->
    console.log params
    @store.find('item', { q: params.query })
