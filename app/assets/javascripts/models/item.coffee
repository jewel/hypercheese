attr = DS.attr

App.Item = DS.Model.extend
  taken: attr('date')
  width: attr('number')
  height: attr('number')
  tags: DS.hasMany('tag')
  isSelected: false

App.Item.reopenClass
  saveTags: (itemIds, tagIds) ->
    App.Ajax(
      url: "/items/tags"
      data:
        items: itemIds
        tags: tagIds
      type: "POST"
    ).then (res) ->
      App.Item.store.pushPayload res
