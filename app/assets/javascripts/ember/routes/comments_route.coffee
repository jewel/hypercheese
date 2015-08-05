App.CommentsRoute = Ember.Route.extend
  model: (params) ->
    console.log 'paonts!'
    @store.query 'comment', item_id: params.item_id
