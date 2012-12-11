#= require jquery.ba-throttle-debounce

class App.SearchResult
  constructor: ->
    @count = 0
    @string = ""
    @loaded_events = false

    $(window).scroll $.throttle(  100, @scroll_label )
    $(window).scroll $.throttle(  250, @wheel_scroll )
    $(window).scroll $.debounce( 1000, @redraw )
    $(window).resize $.throttle(  500, @redraw )

  start: (string, count) ->
    @string = string
    @count = count
    @cache = new App.SearchResultsCache(string, count)
    @redraw()

    $.ajax
      dataType: 'json'
      type: 'GET'
      data:
        q: @string
      url: "/search/events"
      success: (res) =>
        @events = res
        @loaded_events = true

  scroll_label: =>
    return unless @loaded_events
    image_size = 200
    margin = 1

    overdraw = 3

    # calculate number of images in each row
    images_per_row = Math.floor($('#search_results').width() / (image_size + margin*2))

    # calculate height of a row
    row_height = image_size + margin*2

    # calculate which image to start with based on scroll position
    scroll_pos = $(window).scrollTop() - $('#search_results').position().top
    start_row = Math.floor(scroll_pos / row_height)
    start_row = 0 if start_row < 0

    index = start_row * images_per_row
    while index < @count && !@events[index]
      index++

    $('#scroll_label').show()
    $('#scroll_label .subtitle').text @events[index][0] || "???"
    $('#scroll_label .name').text @events[index][1] || ""

    if @label_timer
      clearTimeout @label_timer
    @label_timer = setTimeout(
      ->
        $('#scroll_label').fadeOut('slow')
      1000
    )

  wheel_scroll: =>
    # if the search window is still visible, redraw
    #
    # If we don't skip the redraw while the user is scrolling using the
    # scrollbar, we'll end up queuing up megabytes of images to draw
    win = $('#search_window')
    pos = win.position()
    return if $(window).scrollTop() + $(window).height < pos.top
    return if $(window).scrollTop() > pos.top + win.height()
    @redraw()

  redraw: =>
    image_size = 200
    margin = 1

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


    first_image_index = start_row * images_per_row
    last_image_index = first_image_index + needed

    # are the IDs for these images in the cache?
    unless @cache.contains(first_image_index) && @cache.contains(last_image_index)
      @cache.update first_image_index, needed, @redraw
      return

    # draw enough to cover the current window
    $('#search_window').empty().css
      top: start_row * row_height

    index = first_image_index
    while index < last_image_index
      id = @cache.get(index)
      if id
        html += JST.search_result
          item:
            id:
              id
      index++

    $('#search_window').html(html)
