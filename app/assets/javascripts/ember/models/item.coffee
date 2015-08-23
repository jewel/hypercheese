attr = DS.attr

App.Item = DS.Model.extend
  taken: attr('date')
  width: attr('number')
  height: attr('number')
  tags: DS.hasMany('tag', async: false)
  comments: DS.hasMany('comment', async: true)
  isSelected: false

App.Item.reopenClass
  saveTags: (store, itemIds, tagIds) ->
    App.Ajax(
      url: "/items/add_tags"
      data:
        items: itemIds
        tags: tagIds
      type: "POST"
    ).then (res) ->
      store.pushPayload res

  removeTag: (store, itemIds, tagId) ->
    App.Ajax(
      url: "/items/remove_tag"
      data:
        items: itemIds
        tag: tagId
      type: "POST"
    ).then (res) ->
      store.pushPayload res

  share: (itemIds) ->
    App.Ajax(
      url: "/shares"
      data:
        items: itemIds
      type: "POST"
    ).then (res) ->
      res.url
