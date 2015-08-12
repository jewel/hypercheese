App.CommentsRoute = Ember.Route.extend
  model: (params) ->
    @store.find('item', params.item_id)
