#= require jquery.ba-throttle-debounce

class App.SearchResult
  constructor: ->
    @count = 0
    @string = ""

    $(window).scroll @on_scroll
    $(window).scroll $.debounce( 500, @redraw )
    $(window).resize $.throttle( 500, @redraw )

  start: (string, count) ->
    @string = string
    @count = count
    @redraw()

  on_scroll: (e) =>
    $('#scroll_label').text( $(window).scrollTop() )

  redraw: =>
    image_size = 200
    margin = 4

    overdraw = 3

    # calculate number of images in each row
    images_per_row = Math.floor($('#search_results').width() / (image_size + margin*2))

    # calculate height of a row
    row_height = image_size + margin*2

    $('#search_results').css
      height: (row_height * Math.ceil( @count / images_per_row )) + "px"


    # calculate which image to start with based on scroll position
    scroll_pos = $(window).scrollTop() - $('#search_results').position().top
    start_row = Math.floor(scroll_pos / row_height)
    start_row -= overdraw
    start_row = 0 if start_row < 0

    html = ""
    needed = (Math.ceil( $(window).height() / row_height ) + overdraw * 2) * images_per_row


    first_image = @count - start_row * images_per_row
    last_image = first_image - needed

    # draw enough to cover the current window
    $('#search_window').empty().css
      top: start_row * row_height

    id = first_image
    while id > last_image
      if id > 0
        html += JST.search_result
          item:
            id:
              id
      id--

    $('#search_window').html(html)
