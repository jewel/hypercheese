App.ItemSquareDisplayComponent = Ember.Component.extend
  squareImage: (->
    "/data/resized/square/#{@itemId}.jpg"
  ).property()

  mouseDown: ->
    @wasLongPress = false
    console.log 'down'
    func = =>
      console.log 'long press'
      @wasLongPress = true
      @sendAction @imageLongPress, @itemId

    run = Ember.run.later @, func, 1000
    @longPress = run
    true

  mouseUp: ->
    if !@wasLongPress
      console.log 'click'
      Ember.run.cancel @longPress
      @sendAction @imageClick, @itemId
    else
      console.log 'click canceled'
      false
