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
      Ember.run.throttle @, resize, 100, false

    win.bind 'scroll', =>
      @set 'scrollTop', win.scrollTop()
