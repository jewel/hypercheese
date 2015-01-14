App.SearchRoute = Ember.Route.extend
  queryParams:
    q:
      refreshModel: true

  model: (params) ->
    App.Item.search(params.q).then (res) =>
      # Not yet supported:
      # @store.setMetadataFor 'item', res.meta
      res.search.map (item) =>
        @store.push 'item', item
        item.id
