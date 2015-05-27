# For more information see: http://emberjs.com/guides/routing/

App.Router.map ()->
  @resource 'search', path: '/search', ->
    @route 'zoomed'
  @route 'comments', path: '/v/:item_id/comments'
  @resource 'tags', ->
    @resource 'tag', path: '/:tag_id'
    @route 'new'
