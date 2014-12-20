App.ItemController = Ember.Controller.extend
  largeImage: (->
    "data/resized/large/#{@get 'model.id'}.jpg"
  ).property('model.id')

  

