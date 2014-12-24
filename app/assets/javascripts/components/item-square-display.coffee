App.ItemSquareDisplayComponent = Ember.Component.extend
  squareImage: (->
    "data/resized/square/#{@itemId}.jpg"
  ).property()

  actions:
    imageClick: ->
      @sendAction(@imageClick, @itemId)


