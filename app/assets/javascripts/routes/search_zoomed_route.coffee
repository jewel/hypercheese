App.SearchZoomedRoute = Ember.Route.extend
  activate: -> 
    controller = @controllerFor('search')
    controller.set 'zoomed', true

  deactivate: -> 
    controller = @controllerFor('search')
    controller.set 'zoomed', false
