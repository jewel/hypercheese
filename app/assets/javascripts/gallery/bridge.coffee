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

    # FIXME we need to observe all the individual items, too

  @dump: ->
    state =
      # slice() is needed to avoid circular references for ember arrays
      tags: @tags.map( @toNative ).slice()
      items: @itemRange().map( @toNative )
      resultCount: @results.get('length')
    state

  @update: =>
    @callback @dump()

  @toNative: (obj) ->
    # FIXME: This is probably not the most efficient way to do this
    res = JSON.parse JSON.stringify(obj)
    res.id = obj.get 'id'
    res

  @onChange: (callback) ->
    @callback = callback

  @loadItems: (query, startIndex, endIndex) ->
    return if startIndex == @startIndex && endIndex == @endIndex
    console.log "loading: #{startIndex}, #{endIndex}"
    @startIndex = startIndex
    @endIndex = endIndex
    @update()

  @itemRange: ->
    items = []
    len = @results.get 'length'
    for i in [@startIndex...@endIndex]
      if i >= 0 && i < len
        item = @results.objectAt i
        items.pushObject item
    items
