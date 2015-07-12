#= require ember-sparse-array

App.SearchResults = Ember.SparseArray.extend
  batchSize: 20

  load: (offset, limit) ->
    promise = @store.query 'item',
      query: @query
      offset: offset
      limit: limit

    promise.then (obj) ->
      items:
        obj.get('content')
      total:
        obj.get('meta.total')

  findItem: (item, step) ->
    index = @_data.indexOf(item)

    # FIXME Ask server if not found
    if index == -1
      return null

    nextIndex = index + step

    if nextIndex < 0 || nextIndex >= @get('length')
      return null

    @objectAt(nextIndex)

  prevItem: (item) ->
    findItem item, -1

  nextItem: (item) ->
    findItem item, 1
