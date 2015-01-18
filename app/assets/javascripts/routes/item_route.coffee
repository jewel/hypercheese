App.ItemRoute = Ember.Route.extend
  model: (params) ->
    @store.find('item', params.item_id)

  setupController: (controller, model) ->
    @_super controller, model

    search = @controllerFor 'search'
    unless search.get('model')
      search.set 'model', @store.find( 'search', '' )
