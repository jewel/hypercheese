App.TagMatchComponent = Ember.Component.extend
  tagName: 'li'
  actions:
    removeTag: ->
      @sendAction @removeTag, @tagCount.tag
