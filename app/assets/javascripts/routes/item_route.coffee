App.ItemRoute = Ember.Route.extend
  model: (params) ->
    @store.find('item', params.item_id)
