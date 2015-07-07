App.ApplicationRoute = Ember.Route.extend
  model: ->
    # Preload all tags
    @store.findAll 'tag'
