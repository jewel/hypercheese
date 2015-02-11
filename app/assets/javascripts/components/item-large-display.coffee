App.ItemLargeDisplayComponent = Ember.Component.extend
  afterRenderEvent: (->
    $(window).scrollTop( $('#background').position().top )
  )

  handleResize: (->
    @set 'window_height', $(window).height()
    @set 'window_width', $(window).width()
  )

  bindResizeEvent: (->
    # FIXME We need to unbind this on willDestroy
    $(window).on 'resize', Ember.run.bind(@, @handleResize)
  ).on('init')

  backgroundStyle: (->
    "height: #{@window_height}px"
  ).property('window_height')

  itemStyle: (->
    target_width = @window_width
    target_height = @window_height
    width = @width
    height = @height

    if width > target_width
      height *= target_width / width
      width *= target_width / width

    if height > target_height
      width *= target_height / height
      height *= target_height / height

    margin = 0
    if target_height > height
      margin = Math.floor (target_height-height)/2

    "width: #{Math.floor(width)}px; height: #{Math.floor(height)}px; margin-top: #{margin}px;"
  ).property('itemId', 'window_width', 'window_height')

  window_width: $(window).width()

  window_height: $(window).height()

  largeImage: (->
    "data/resized/large/#{@itemId}.jpg"
  ).property('itemId')
