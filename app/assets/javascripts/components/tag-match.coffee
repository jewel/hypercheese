App.TagMatchComponent = Ember.Component.extend
  actions:
    removeTag: ->
      @sendAction @removeTag, @tag
