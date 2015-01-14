attr = DS.attr

App.Item = DS.Model.extend
  taken: attr('date')
  width: attr('number')
  height: attr('number')
  tags: DS.hasMany('tag')

App.Item.reopenClass
  search: (query) ->
    $.ajax(
      cache: false
      url: '/search'
      data:
        q: query
      type: 'GET'
      dataType: 'json'
    )
