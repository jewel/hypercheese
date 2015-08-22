App.TagMatchComponent = Ember.Component.extend
  tagName: 'li'
  actions:
    removeTag: ->
      @sendAction @get('removeTag'), @get('tagCount').tag
