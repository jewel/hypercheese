App.SearchRoute = Ember.Route.extend
  offset: 0
  limit: 1000

  queryParams:
    q:
      refreshModel: true

  model: (params) ->
    @store.find 'item',
      query: params.q
      offset: @get('offset')
      limit: @get('limit')

  setupController: (controller, model) ->
    @_super controller, model
    controller.setProperties
      offset: @get('offset')
      limit: @get('limit')
