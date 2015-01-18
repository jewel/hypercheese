App.SearchController = Ember.Controller.extend
  queryParams: ['q']
  q: ''

  nextItem: (item) ->
    items = @get('model.items.content')
    index = items.indexOf(item)
    nextIndex = index + 1
    if nextIndex >= items.length
      nextIndex = 0
    next = items.objectAt(nextIndex)
    @transitionToRoute 'item', next.id


  previousItem: (item) ->
    items = @get('model.items.content')
    index = items.indexOf(item)
    prevIndex = index - 1
    if prevIndex < 0
      prevIndex = items.length - 1
    prev = items.objectAt(prevIndex)
    @transitionToRoute 'item', prev.id

  all: ( ->
    @model.all()
  ).property('model')

  actions:
    imageClick: (itemId)->
      @transitionToRoute 'item', itemId
