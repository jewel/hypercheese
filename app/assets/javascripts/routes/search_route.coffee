App.SearchRoute = Ember.Route.extend
  queryParams:
    q:
      refreshModel: true

  model: (params) ->
    App.SearchResults.create
      query: params.q
      store: @store
