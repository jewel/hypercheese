App.IndexRoute = Ember.Route.extend
  model: ->
    @store.filter('item', { top: 100 })
