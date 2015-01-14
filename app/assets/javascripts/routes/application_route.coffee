App.ApplicationRoute = Ember.Route.extend
  model: ->
    # Preload all tags
    @store.find 'tag'
