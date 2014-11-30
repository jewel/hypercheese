# For more information see: http://emberjs.com/guides/routing/

App.Router.map ()->
  @resource 'search', path: '/search/:query'
  @resource 'item', path: '/v/:item_id'
