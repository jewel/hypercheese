App.ItemLargeDisplayComponent = Ember.Component.extend
  afterRenderEvent: (->
    $(window).scrollTop $('#background').position().top
  )

  window: App.Window

  backgroundStyle: (->
    "height: #{@get('window.height')}px"
  ).property('window.height')

  itemStyle: (->
    window = @get('window')
    target_width = window.get 'width'
    target_height = window.get 'height'
    width = @get 'width'
    height = @get 'height'

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
  ).property('window.width', 'window.height', 'height', 'width')

  largeImage: (->
    "/data/resized/large/#{@itemId}.jpg"
  ).property('itemId')
