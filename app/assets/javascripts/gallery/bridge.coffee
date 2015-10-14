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

    @selection = selection = Ember.ArrayProxy.create
      content: []

    App.Item.reopen
      isDirtyObserver: Ember.observer 'attributes,isSelected', =>
        @update()

      updateSelection: Ember.observer 'isSelected', ->
        console.log 'updateSelection'
        if @get('isSelected')
          selection.addObject @
        else
          selection.removeObject @
        console.log selection

  @dump: ->
    state =
      tags: @tags
      results: @results
      selection: @selection
    state

  @update: =>
    @callback @dump()

  @onChange: (callback) ->
    @callback = callback
