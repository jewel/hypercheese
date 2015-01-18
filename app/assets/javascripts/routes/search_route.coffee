App.SearchRoute = Ember.Route.extend
  queryParams:
    q:
      refreshModel: true

  model: (params) ->
    @store.find 'search', params.q
