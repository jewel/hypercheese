App.SearchResult = Ember.Object.extend
  query: ""

  all: ->
    @_load().then (data) ->
      data.search.items

  # load all items in positional range
  getRange: (start, finish) ->
    @_load().then (data) ->
      items = []
      for i in [start...finish]
        items.push data.search.items[i]
      items

  getNext: (item_id) ->
    @_load().then (data) ->
      collection = data.search.items
      for item, index in collection
        continue unless item.id == item_id
        return null if index+1 == collection.length
        return collection[index+1]
      null

  getPrev: (item_id) ->
    @_load().then (data) ->
      collection = data.search.items
      for item, index in collection
        continue unless item.id == item_id
        return null if index == 0
        return collection[index-1]
      null

  _load: () ->
    return @_cache if @_cache

    # TODO push the item data into the ember data store
    @_cache = App.Ajax
      cache: false
      url: '/search'
      data:
        q: @query
      type: 'GET'
      dataType: 'json'
      success: (data) =>
        @set 'count', data.search.count
