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
      url: "/items/add_tags"
      data:
        items: itemIds
        tags: tagIds
      type: "POST"
    ).then (res) ->
      App.Item.store.pushPayload res

  removeTag: (itemIds, tagId) ->
    App.Ajax(
      url: "/items/remove_tag"
      data:
        items: itemIds
        tag: tagId
      type: "POST"
    ).then (res) ->
      App.Item.store.pushPayload res

  share: (itemIds) ->
    App.Ajax(
      url: "/shares"
      data:
        items: itemIds
      type: "POST"
    ).then (res) ->
      res.url
