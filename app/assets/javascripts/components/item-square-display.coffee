App.ItemSquareDisplayComponent = Ember.Component.extend
  squareImage: Ember.computed 'item.id', ->
    "/data/resized/square/#{@get('item.id')}.jpg"

  imageStyle: Ember.computed 'imageSize', ->
    "width: #{@get('imageSize')}px; height: #{@get('imageSize')}px"

  bgStyle: Ember.computed 'item.bgcolor', ->
    "background-color: #{@get('item.bgcolor')}"

  mouseDown: ->
    @wasLongPress = false
    func = =>
      @wasLongPress = true
      @sendAction @imageLongPress, @get('item')

    run = Ember.run.later @, func, 1000
    @longPress = run
    true

  mouseUp: ->
    if !@wasLongPress
      Ember.run.cancel @longPress
      @sendAction @imageClick, @get('item')
    else
      false
