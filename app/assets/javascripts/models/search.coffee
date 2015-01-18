App.SearchAdapter = App.ApplicationAdapter.extend
  find: (store, type, query) ->
    App.Ajax(
      cache: false
      url: '/search'
      data:
        q: query
      type: 'GET'
      dataType: 'json'
    ).then (data) ->
      data.search.id = query
      unless query
        data.search.id = 'empty-search!'
      data

App.Search = DS.Model.extend
  items: DS.hasMany('item')
  count: DS.attr('number')
