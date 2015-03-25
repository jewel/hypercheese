App.SearchZoomedRoute = Ember.Route.extend
  activate: -> 
    controller = @controllerFor('search')
    controller.set 'zoomed', true

  deactivate: -> 
    controller = @controllerFor('search')
    if controller.get 'zoomed'
      index = controller.get 'getZoomedIndex'
      controller.scrollToIndex(index)
      controller.set 'zoomed', false
