App.ItemDisplayComponent = Ember.Component.extend
  afterRenderEvent: (->
    $(window).scrollTop( $('#background').position().top )
    console.log("scroll")
  )

  backgroundStyle: (->
    "height: #{$(window).height()}px"
  ).property()

  itemStyle: (->
    target_width = $(window).width()
    target_height = $(window).height()
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
  ).property()

  largeImage: (->
    "data/resized/large/#{@itemId}.jpg"
  ).property()
