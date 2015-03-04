# Singleton
win = $(window)

App.Window = Ember.Object.create
  width: win.width()

  height: win.height()

  scrollTop: win.scrollTop()

  init: ->
    resize = =>
      @setProperties
        width: win.width()
        height: win.height()

    win.bind 'resize', =>
      Ember.run.throttle @, resize, 1000, false

    scroll = =>
      @set 'scrollTop', win.scrollTop()

    win.bind 'scroll', =>
      Ember.run.throttle @, scroll, 1000, false
