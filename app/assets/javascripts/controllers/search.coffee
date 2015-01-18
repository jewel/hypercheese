App.SearchController = Ember.ArrayController.extend
  queryParams: ['q']
  q: ''

  init: ->
    @_scroll_callback = => @send('scroll')
    $(window).bind 'scroll', @_scroll_callback

    @_super()

  willDestroy: ->
    $(window).unbind 'scroll', @_scroll_callback

  nextItem: (item) ->
    items = @get('model')
    console.log items
    index = items.indexOf(item)
    nextIndex = index + 1
    if nextIndex >= items.length
      nextIndex = 0
    next = items.objectAt(nextIndex)
    @transitionToRoute 'item', next.id

  previousItem: (item) ->
    items = @get('model')
    index = items.indexOf(item)
    prevIndex = index - 1
    if prevIndex < 0
      prevIndex = items.length - 1
    prev = items.objectAt(prevIndex)
    @transitionToRoute 'item', prev.id

  actions:
    scroll: ->
      func = ->
        console.log "Scroll to #{$(window).scrollTop()}"
      Ember.run.debounce @, func, 1000

    imageClick: (itemId)->
      @transitionToRoute 'item', itemId
