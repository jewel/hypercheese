#= require spine
#= require spine/manager
#= require spine/list
#= require spine/ajax
#= require spine/route
#
#= require_tree ./lib
#= require_self
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree .

class @App
  constructor: ->
    # Initialize controllers
    @tag_list = new App.TagListController
      el: '#tags'

    App.Tag.fetch()
    @item = App.Item.fetch( id: $item_id )

$ ->
  window.app = new App
