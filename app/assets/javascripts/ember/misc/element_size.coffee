# Singleton

App.ElementSize = Ember.Object.extend
  init: ->
    element = @get('element')

    @setProperties
      width: element.width()
      height: element.height()
      scrollTop: element.scrollTop()

    element.on 'resize', =>
      Ember.run.throttle @, @onResize, 100, false

    element.on 'scroll', =>
      Ember.run =>
        @set 'scrollTop', element.scrollTop()

  onResize: ->
    @setProperties
      width: @get('element').width()
      height: @get('element').height()
