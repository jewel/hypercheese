App.ItemSquareDisplayComponent = Ember.Component.extend
  squareImage: Ember.computed 'item.id', ->
    "/data/resized/square/#{@get('item.id')}.jpg"

  imageStyle: Ember.computed 'imageSize', ->
    "width: #{@get('imageSize')}px; height: #{@get('imageSize')}px"

  bgStyle: Ember.computed 'item.bgcolor', 'item.isSelected', ->
    # The background color shines through when an item is selected
    color = if @get('item.isSelected')
      "blue"
    else
      @get('item.bgcolor')
    "background-color: #{color}"

  mouseDown: (e) ->
    if e.which != 1
      return false

    @wasLongPress = false
    func = =>
      @wasLongPress = true
      @sendAction @imageLongPress, @get('item')

    run = Ember.run.later @, func, 1000
    @longPress = run
    true

  mouseUp: (e) ->
    if e.which != 1
      return false

    if !@wasLongPress
      Ember.run.cancel @longPress
      @sendAction @imageClick, @get('item')
      true
    else
      false
