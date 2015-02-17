App.ItemController = Ember.Controller.extend
  needs: ['search']

  filteredTags: @tags
  tags: null
  selectedTagId: null


  filterTagsBy: (term) ->
    tags = @tags
    return tags if (!term)
    filter = new RegExp('^'+term, 'i')
    return tags.filter((tag) ->
      return filter.test(tag.get('label')) #|| filter.test(tag.id)
    )

  setTag: (->
    selectedTagId = @get('selectedTagId')
    return if selectedTagId == null

    @store.find('tag', selectedTagId).then (tag)=>
      @get('model.tags').addObject(tag)
      @get('model').saveTags()
  ).observes('selectedTagId')

  clearSelected: (->
    $(".ic-autocomplete-input").val("")
    console.log "clear"
  ).observes('model')
   
  setupTags: ->
    @store.find('tag').then (tags) =>
      sortedTags = tags.content.sortBy('label')
      @set('tags', sortedTags)
      @set('filteredTags', sortedTags)

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
