App.PaginatedBaseRoute = Ember.Route.extend
  offset: 0
  limit: 10

  queryParams: {
    page: {
      refreshModel: true
    }
  }

  init: (domain) ->
    @_super()
    @set('domain', domain)

  model: (params) ->
    if (params.page)
      page = params.page
      # avoid page numbers to be trolled i.e.: page=string, page=-1, page=1.23
      if isNaN(page)
        page = 1
      else 
        page = Math.floor(Math.abs(page))
      # page=1 will result into offset 0, page=2 will result into offset 10 and so on
      @set('offset', (page-1)*@get('limit'))

      @store.find(@get('domain'), { offset: @get('offset'), limit: @get('limit') })

  setupController: (controller, model) ->
    @_super(controller, model)
    controller.setProperties(
      offset: @get('offset')
      limit: @get('limit')
    )




