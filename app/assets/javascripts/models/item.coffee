attr = DS.attr

App.Item = DS.Model.extend
  taken: attr('date')
  width: attr('number')
  height: attr('number')
  tags: DS.hasMany('tag')
  isSelected: false
  bgcolor: Ember.computed ->
    '#' + ('000000' + Math.floor(Math.random() * 16777216).toString(16)).slice(-6)

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
