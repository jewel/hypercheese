App.ItemSquareDisplayComponent = Ember.Component.extend
  squareImage: Ember.computed 'item.id', ->
    "/data/resized/square/#{@get('item.id')}.jpg"

  imageStyle: Ember.computed 'imageSize', ->
    "width: #{@get('imageSize')}px; height: #{@get('imageSize')}px"

  bgStyle: Ember.computed 'item.bgcolor', ->
    "background-color: #{@get('item.bgcolor')}"

  mouseDown: ->
    @wasLongPress = false
    console.log 'down'
    func = =>
      console.log 'long press'
      @wasLongPress = true
      @sendAction @imageLongPress, @get('item.id')

    run = Ember.run.later @, func, 1000
    @longPress = run
    true

  mouseUp: ->
    if !@wasLongPress
      console.log 'click'
      Ember.run.cancel @longPress
      @sendAction @imageClick, @get('item.id')
    else
      console.log 'click canceled'
      false
