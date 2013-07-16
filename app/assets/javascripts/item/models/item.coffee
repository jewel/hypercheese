class App.Item extends Spine.Model
  @configure 'Item', 'tags'
  @extend Spine.Model.Ajax

  add_tag: (tag) ->
    return unless @tags.indexOf(tag.id) == -1
    @tags.push tag.id
    Spine.Ajax.queue =>
      $.ajax
        type: 'PUT'
        cache: false
        url: "/items/#{@id}/tags/#{tag.id}"

    Spine.Ajax.disable =>
      @save()

  remove_tag: (tag) ->
    @tags = _(@tags).without tag.id
    Spine.Ajax.queue =>
      $.ajax
        type: 'DELETE'
        cache: false
        url: "/items/#{@id}/tags/#{tag.id}"

    Spine.Ajax.disable =>
      @save()
