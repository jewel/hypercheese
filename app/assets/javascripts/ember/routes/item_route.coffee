App.ItemRoute = Ember.Route.extend
  model: (params) ->
    @store.find('item', params.item_id)

  setupController: (controller, model) ->
    @_super controller, model
    controller.setupTags()

    search = @controllerFor 'search'
    if search.get('model').length == 0
      results = App.SearchResults.create
        query: params.q
        store: @store
      search.set 'model', results
