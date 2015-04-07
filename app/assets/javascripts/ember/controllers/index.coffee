App.IndexController = Ember.ArrayController.extend App.PaginatedMixin,
  total: (->
    @store.metadataFor('item').total
  ).property('model')

  actions:
    imageClick: (itemId)->
      @transitionToRoute 'item', itemId
