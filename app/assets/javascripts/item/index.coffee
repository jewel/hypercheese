return unless $('#item').length > 0

resize_image = ->
  target_width = $(window).width()
  target_height = $(window).height()
  width = $width
  height = $height

  if width > target_width
    height *= target_width / width
    width *= target_width / width

  if height > target_height
    width *= target_height / height
    height *= target_height / height

  margin = 0
  if target_height > height
    margin = Math.floor (target_height-height)/2

  $('#item').css
    width: Math.floor(width)
    height: Math.floor(height)
    marginTop: margin

  middle = (target_height-256)/2

  $('#play').css
    position: 'absolute'
    left: Math.floor((target_width-250)/2)
    top: middle

  $('#background, #prev, #next').css 'height', target_height
  $('#prev img, #next img').css 'margin-top', middle
  $('#fav').css
    top: target_height - 256
    left: target_width/2 - 256/2
  $('#logo').css 'top', target_height

$(window).resize resize_image

do resize_image

$(window).scrollTop( $('#background').position().top )

$ ->

  $('#authbox').prependTo '.info'
  if $next_image
    $('<img/>')
      .attr( 'src', $next_image )
      .appendTo( 'body' )
      .hide()

  $('#item').click ->
    $("#prev img, #next img").css('visibility', 'visible')

  $('#play').click ->
    $('#item').remove()
    $(@).remove()
    video = $('<video id="item" controls="controls">')
      .appendTo( '#background' )

    $('<source>')
      .attr( 'src', $ogv_url )
      .appendTo( video )
    $('<source>')
      .attr( 'src', $mp4_url )
      .appendTo( video )

    video.append( "Sorry, it appears your browser doesn't support video" )

    video[0].play()
    resize_image()
    false
