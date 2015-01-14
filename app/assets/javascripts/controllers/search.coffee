App.SearchController = Ember.Controller.extend
  queryParams: ['q']
  q: ''

  actions:
    imageClick: (itemId)->
      @transitionToRoute 'item', itemId
