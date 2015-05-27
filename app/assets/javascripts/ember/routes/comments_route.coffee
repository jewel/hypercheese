App.CommentsRoute = Ember.Route.extend
  model: (params) ->
    console.log 'pants!'
    @store.find 'comment', item_id: params.item_id
