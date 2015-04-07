App.SearchRoute = Ember.Route.extend
  queryParams:
    q:
      refreshModel: true

  model: (params) ->
    # FIXME This shouldn't return until we know how many search results there
    # are, because we can't render the search window until we know the right
    # height.  (Otherwise we break the back button, badly
    App.SearchResults.create
      query: params.q
      store: @store
