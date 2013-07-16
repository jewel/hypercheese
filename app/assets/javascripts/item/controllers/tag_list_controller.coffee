class App.TagListController extends Spine.Controller
  constructor: ->
    super

    App.Item.bind 'refresh create update', @render

  render: =>
    @el.empty()

    @item = App.Item.first()
    ul = $('<ul>')
    @el.append(ul)

    @item.tags.forEach (tag_id) =>
      tag = App.Tag.find tag_id
      li = $('<li>').appendTo ul
      li.text( tag.label )

      $('<a href="javascript:void(0)">&times</a>')
        .appendTo(li)
        .click =>
          @item.remove_tag(tag)

    input = $('<input autocomplete="off" type="text">')
    @el.append input

    tags = App.Tag.all().map (tag) ->
      tag.label

    input.typeahead
      source: tags
      updater: (label) =>
        tag = App.Tag.findByLabel( label )
        @item.add_tag(tag)
