#= require ember-sparse-array

App.SearchResults = Ember.SparseArray.extend
  batchSize: 20
  load: (offset, limit) ->
    promise = @store.find 'item',
      query: @query
      offset: offset
      limit: limit

    promise.then (obj) ->
      items:
        obj.get('content')
      total:
        obj.get('meta.total')
