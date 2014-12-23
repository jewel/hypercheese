App.Paginated = Ember.Mixin.create 
  queryParams: ['page']
  page: 1
  offset: 0

  hasPreviousPage: (->
    @get('offset') != 0
  ).property('offset')
  hasNextPage: (->
    (@get('offset') + @get('limit')) < @get('total')
  ).property('offset', 'limit', 'total')

  actions: 
    previousPage: ->
      # has a page that is higher than the actual total pages (this is only possible manually)
      # get the last possible page number
      totalPages = Math.ceil(@get('total')/@get('limit'))
      if @decrementProperty('page') > totalPages
        @set('page', totalPages)

      @transitionToRoute( queryParams: {
        page: @get('page')
      })

    nextPage: ->
      @transistionToRoute( queryParams: {
        page: @incrementProperty('page')
      })


App.IndexController = Ember.ArrayController.extend App.Paginated,

  total: (->
    console.log @store.metadataFor('item').total
    @store.metadataFor('item').total
  ).property('model')

