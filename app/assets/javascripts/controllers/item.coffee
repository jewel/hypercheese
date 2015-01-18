App.ItemController = Ember.Controller.extend
  needs: ['search']

  actions:
    getNextItem: ->
      @get('controllers.search').nextItem(@get('model'))
    getPrevItem: ->
      @get('controllers.search').previousItem(@get('model'))
