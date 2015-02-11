App.SearchController = Ember.Controller.extend
  queryParams: ['q']
  q: ''

  imageSize: 200
  margin: 1
  overdraw: 3

  window: App.Window

  columnWidth: Ember.computed 'imageSize', 'margin', ->
    @get('imageSize') + @get('margin') * 2

  rowHeight: Ember.computed 'imageSize', 'margin', ->
    @get('imageSize') + @get('margin') * 2

  imagesPerRow: Ember.computed 'window.width', 'rowHeight', ->
    Math.floor @get('window.width') / @get('rowHeight')

  rowCount: Ember.computed 'content.length', 'imagesPerRow', ->
    Math.ceil @get('content.length') / @get('imagesPerRow') + @overdraw * 2

  resultsStyle: Ember.computed 'rowHeight', 'rowCount', ->
    "height: #{@get('rowHeight') * @get('rowCount')}px"

  viewPortStartRow: Ember.computed 'window.scrollTop', 'rowHeight', ->
    val = Math.floor @get('window.scrollTop') / @get('rowHeight') - @overdraw
    val = 0 if val < 0
    val

  viewPortStyle: Ember.computed 'viewPortStartRow', 'rowHeight', ->
    "top: #{@get('viewPortStartRow') * @get('rowHeight')}px"

  viewPortRowCount: Ember.computed 'window.height', 'rowHeight', ->
    Math.ceil @get('window.height') / @get('rowHeight') + @overdraw

  # Return items that are within visible viewport
  viewPortItems: Ember.computed 'model.loadCount', 'imagesPerRow', 'viewPortStartRow', 'viewPortRowCount', 'selected', ->
    startIndex = @get('viewPortStartRow') * @get('imagesPerRow')
    endIndex = startIndex + @get('viewPortRowCount') * @get('imagesPerRow')

    console.log "Should show #{startIndex} to #{endIndex}"

    items = []
    len = @get('model.length')
    for i in [startIndex...endIndex]
      if i > 0 && i < len
        item = @get('model').objectAt(i)
        items.pushObject
          model: item
          selected: @get('selected')[item.id]
    items

    Ember.ArrayProxy.create
      content: items

  selected: {}
  selecting: true

  actions:
    imageClick: (itemId) ->
      if @get('selecting')
        @get('selected')[itemId] = true
        @set 'selected', @get('selected')
        false
      else
        @transitionToRoute 'item', itemId
