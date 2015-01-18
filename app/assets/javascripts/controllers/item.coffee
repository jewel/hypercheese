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
      
  actions:
    getNextItem: ->
      @get('controllers.search').nextItem(@get('model'))
    getPrevItem: ->
      @get('controllers.search').previousItem(@get('model'))

    filterTags: (autocomplete, term) ->
      @set('filteredTags', @filterTagsBy(term))

    resetTags: ->
      @set('filteredTags', @tags) 
