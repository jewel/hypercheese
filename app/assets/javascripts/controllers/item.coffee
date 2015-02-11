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
      
  actions:
    getNextItem: ->
      @get('controllers.search').nextItem(@get('model'))
    getPrevItem: ->
      @get('controllers.search').previousItem(@get('model'))

    filterTags: (autocomplete, term) ->
      @set('filteredTags', @filterTagsBy(term))

    resetTags: () ->
      @set('filteredTags', @tags) 
