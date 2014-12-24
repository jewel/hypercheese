# For more information see: http://emberjs.com/guides/routing/

App.Router.map ()->
  @resource 'search', path: '/search/:query'
  @resource 'items', path: '/v', ->
    @resource 'item', path: '/:item_id'
