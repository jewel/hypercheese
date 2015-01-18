App.SearchRoute = Ember.Route.extend
  queryParams:
    q:
      refreshModel: true

  model: (params) ->
    App.SearchResult.create
      query: params.q
