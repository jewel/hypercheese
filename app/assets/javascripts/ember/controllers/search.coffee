App.SearchController = Ember.Controller.extend
  queryParams: ['q']
  q: ''


  window: App.Window


  newTags: ''
  tags: []
  init: ->
    @store.findAll('tag').then (tags) =>
      @set 'tags', tags.sortBy('count').toArray().reverse()
    @_super()

  minColumns: 3
  maxSquareSize: 200
  margin: 2
  overdraw: 3
  # FIXME Can we detect how much space the scrollbars are taking?
  scrollbarWidth: 14
  toolbarHeight: 52
  zoomed: false

  imageSquareSize: Ember.computed 'window.width', ->
    width = @get 'window.width'
    columnSize = ( @maxSquareSize + @margin * 2 ) * @minColumns
    if width >= columnSize
      @maxSquareSize
    else
      width / @minColumns - @margin * 2

  maxImageWidth: Ember.computed 'imageSquareSize', 'zoomed', 'window.height', 'window.width', ->
    if @get('zoomed')
      @get('window.width') - @margin*2 - @scrollbarWidth
    else
      @get 'imageSquareSize'

  maxImageHeight: Ember.computed 'imageSquareSize', 'zoomed', 'window.height', 'window.width', ->
    if @get('zoomed')
      @get('window.height') - @margin*2 - @toolbarHeight
    else
      @get 'imageSquareSize'

  columnWidth: Ember.computed 'maxImageWidth', ->
    @get('maxImageWidth') + @margin * 2

  rowHeight: Ember.computed 'maxImageHeight', ->
    @get('maxImageHeight') + @margin * 2

  imagesPerRow: Ember.computed 'window.width', 'columnWidth', 'zoomed', ->
    unless @get('zoomed')
      Math.floor @get('window.width') / @get('columnWidth')
    else
      1

  rowCount: Ember.computed 'content.length', 'imagesPerRow', ->
    Math.ceil @get('content.length') / @get('imagesPerRow')

  resultsClass: Ember.computed 'zoomed', ->
    if @get('zoomed')
      "results zoomed"
    else
      "results"

  resultsStyle: Ember.computed 'rowHeight', 'rowCount', ->
    Ember.String.htmlSafe "height: #{@get('rowHeight') * @get('rowCount')}px"


  # scrollTop is the same as window.scrollTop, except we only change it when we
  # want to force a redraw.  otherwise there are too many scroll events

  scrollTopChange: Ember.observer 'window.scrollTop', ->
    # @set 'scrollTop', @get('window.scrollTop')
    # Only redraw if we have scrolled outside of what is already there
    viewPortTop = @get('viewPortStartRow') * @get('rowHeight')
    viewPortSize = @get('viewPortRowCount') * @get('rowHeight')
    scrollTop = @get('window.scrollTop')
    #if scrollTop < viewPortTop || scrollTop > viewPortTop + viewPortSize - @get('window.height')
    console.log "redraw"
    @set 'scrollTop', scrollTop

  scrollTop: 0

  scrollPos: Ember.computed 'scrollTop', ->
    @get('scrollTop') - @get('toolbarHeight')

  viewPortStartRow: Ember.computed 'scrollPos', 'rowHeight', ->
    val = Math.floor @get('scrollPos') / @get('rowHeight') - @overdraw
    val = 0 if val < 0
    val

  viewPortStyle: Ember.computed 'viewPortStartRow', 'rowHeight', ->
    Ember.String.htmlSafe "top: #{@get('viewPortStartRow') * @get('rowHeight')}px"

  viewPortRowCount: Ember.computed 'window.height', 'rowHeight', ->
    Math.ceil @get('window.height') / @get('rowHeight') + @overdraw * 2

  # Return items that are within visible viewport
  viewPortItems: Ember.computed 'model.loadCount', 'imagesPerRow', 'viewPortStartRow', 'viewPortRowCount', ->
    startIndex = @get('viewPortStartRow') * @get('imagesPerRow')
    endIndex = startIndex + @get('viewPortRowCount') * @get('imagesPerRow')

    console.log "#{@get('viewPortStartRow')} * #{@get('imagesPerRow')} = #{startIndex}"
    console.log "#{startIndex} + #{@get('viewPortRowCount')} * #{@get('imagesPerRow')} = #{endIndex}"

    items = []
    len = @get('model.length')
    model = @get('model')

    for i in [startIndex...endIndex]
      if i >= 0 && i < len
        item = model.objectAt(i)
        Ember.set(item, 'position', i)
        items.pushObject item
    items

    Ember.ArrayProxy.create
      content: items

  selected: []

  select: (item) ->
    unless item.get('isSelected')
      item.set 'isSelected', true
      @get('selected').addObject item

  unSelect: (item) ->
    if item.get('isSelected')
      item.set 'isSelected', false
      @get('selected').removeObject item


  toggleSelection: (item) ->
    if item.get('isSelected')
      @unSelect(item)
    else
      @select(item)

  matchOne: (str) ->
    return null if str == ''

    for tag in @get('tags')
      continue unless tag.get('label').toLowerCase().indexOf( str.toLowerCase() ) == 0
      return tag

    return null

  matchMany: (str) ->
    if !str? || str == ''
      return []

    # check for exact match
    tags = @get('tags')

    for tag in tags
      continue unless tag.get('label').toLowerCase() == str.toLowerCase()
      return [tag]

    # attempt to split by comma
    matches = []
    for part in str.split( /,\ */ )
      res = @matchOne part
      matches.push res if res

    return matches if matches.length > 0

    # attempt to split by whitespace
    for part in str.split( /\ +/ )
      res = @matchOne part
      matches.push res if res

    return matches if matches.length > 0

    return []

  tagMatches: Ember.computed 'tags', 'newTags', ->
    Ember.ArrayProxy.create
      content: @matchMany( @get('newTags') )

  selectedTags: Ember.computed 'selected.@each.tags', ->
    index = {}
    tags = []
    @get('selected').forEach (item) ->
      item.get('tags').forEach (tag) ->
        obj = index[tag.id]
        if !obj
          obj = index[tag.id] = Ember.Object.create
            tag: tag
            count: 0
          tags.push obj
        obj.incrementProperty('count')

    tags

  downloadLink: Ember.computed 'selected.@each', ->
    itemIds = @get('selected').mapBy('id').join(",")
    "/items/download?ids=#{itemIds}"

  scrollToIndex: (index) ->
    if index?
      Ember.run.scheduleOnce 'afterRender', @, ->
        console.log "Scrolling to #{index} / #{@get('imagesPerRow')} * #{@get('rowHeight')}"
        $(window).scrollTop Math.floor(index / @get('imagesPerRow')) * @get('rowHeight')

  clearSelection: () ->
    @get('selected').forEach (item) ->
      item.set 'isSelected', false
    @set('selected', [])

  actions:
    imageZoom: (item) ->
      @set 'zoomed', !@get('zoomed')
      if @get 'zoomed'
        @toggleSelection item
        @transitionToRoute('search.zoomed')
      else
        @transitionToRoute('search')

      index = @get('content').findLoadedObjectIndex item
      @scrollToIndex(index)

    lineSelect: (item) ->
      @clearSelection()
      start = @get('startSelection')
      unless start?
        @select(item)
        @set('startSelection', item)
        return
      startIndex = @get('content').findLoadedObjectIndex start
      endIndex = @get('content').findLoadedObjectIndex item
      if startIndex > endIndex
        [startIndex, endIndex] = [endIndex, startIndex]
      index = startIndex
      while index <= endIndex
        i = @get('content').objectAt(index)
        console.log(i)
        @select(i)
        index += 1

    toggleSelection: (item) ->
      @toggleSelection item

    imageSelect: (item) ->
      @clearSelection()
      @set('startSelection', item)
      @toggleSelection item

    clearSelected: ->
      @set('startSelection', null)
      @clearSelection()

    shareSelection: ->
      itemIds = @get('selected').mapBy 'id'
      App.Item.share(itemIds).then (url) ->
        window.prompt "The items are available at this link:", url

    saveNewTags: ->
      itemIds = @get('selected').mapBy 'id'
      tagIds = @matchMany( @get('newTags') ).mapBy 'id'

      if tagIds.length > 0
        App.Item.saveTags itemIds, tagIds
        @set 'newTags', ''

    removeTag: (tag) ->
      itemIds = @get('selected').mapBy 'id'

      App.Item.removeTag itemIds, tag.id
