App.ItemController = Ember.Controller.extend
  needs: ['search']

  filteredTags: @tags
  tag: null
  tags: null

  filterTagsBy: (term) ->
    tags = @tags
    return tags if (!term)
    filter = new RegExp('^'+term, 'i')
    return tags.filter((tag) ->
      return filter.test(tag.get('label')) #|| filter.test(tag.id)
    )

  setupTags: ->
    @store.find('tag').then (tags) =>
      @set('tags', tags.content)
      @set('filteredTags', tags.content)

  nextItem: Ember.computed 'model', ->
    @get('controllers.search').nextItem @get('model')

  prevItem: Ember.computed 'model', ->
    @get('controllers.search').prevItem @get('model')

  _preload: (id) ->
    return unless id
    new Image().src = "/data/resized/large/#{id}.jpg"
    false

  itemDidChange: (->
    @_preload( @get('nextItem.id') )
    @_preload( @get('prevItem.id') )
  ).observes('nextItem', 'prevItem')

  actions:
    getNextItem: ->
      @get('nextItem')
    getPrevItem: ->
      @get('prevItem')

    filterTags: (autocomplete, term) ->
      @set('filteredTags', @filterTagsBy(term))

    resetTags: ->
      @set('filteredTags', @tags)
