attr = DS.attr

App.Item = DS.Model.extend
  taken: attr('date')
  width: attr('number')
  height: attr('number')
  tags: DS.hasMany('tag')

  saveTags: ->
    tagIds = @get('tags').map (tag)->
      tag.id

    App.Ajax
      url: "/items/tags"
      data: 
        item:
          tags: tagIds
          id: @get('id')
      type: "POST"
      dataType: "json"

