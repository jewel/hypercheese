class @Bridge
  @init: ->
    @store = App.__container__.lookup('service:store')

    # Initial loads
    @tags = @store.findAll('tag')
    @results = App.SearchResults.create
      query: ''
      store: @store

    @tags.addObserver( '@each', @update )
    @results.addObserver( 'loadCount', @update )
    App.Item.reopen
      isDirtyObserver: Ember.observer 'attributes,isSelected', =>
        @update()

    # FIXME we need to observe all the individual items, too

  @dump: ->
    state =
      tags: @tags
      results: @results
    state

  @update: =>
    @callback @dump()

  @onChange: (callback) ->
    @callback = callback
