App.ItemRoute = Ember.Route.extend
  model: (params) ->
    @store.find('item', params.item_id)

  setupController: (controller, model) ->
    @_super controller, model

    search = @controllerFor 'search'
    if search.get('model').length == 0
      search.set 'model', @store.find( 'item', { query: '' } )
