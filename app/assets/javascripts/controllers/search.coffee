App.SearchController = Ember.ArrayController.extend
  queryParams: ['q']
  q: ''

  actions:
    imageClick: (itemId)->
      @transitionToRoute 'item', itemId
