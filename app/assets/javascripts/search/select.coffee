$ ->
  selected_items = ->
    $('.item a.selected')

  all = $('.item a')

  advanced = ->
    $('#multi')[0].checked

  selected_items().each ->
    $(@).data( 'tags', $(@).data( 'tags' ) )

  save = ->
    return unless selected_items().length > 0

    data = {}
    selected_items().each ->
      data[ $(@).attr('id') ] = $(@).data( 'tags' )
    $.post '/item/tags'
      data: JSON.stringify( data )

  show_icons = (item) ->
    item = $(item)
    icons = item.find( '.icons' ).empty()
    for i, v of item.data( 'tags' )
      continue unless v
      continue unless $tag_icons[i]
      icon = $('<span class="icon">')
        .appendTo icons
      $('<img>')
        .attr( 'src', $tag_icons[i] )
        .appendTo icon
      $('<span class="label">').text( $tags[i] )
        .appendTo icon

  create_event = ->
    name = prompt 'Name of new event?'
    return if name == null
    items = []
    selected_items().each ->
      items.push $(@).attr('id')

    $.post '/event/create',
      name: name
      items: items.join( ',' )
      ->
        alert 'New event created, please refresh'

  draw_tag = (label, id, count) ->
    li = $('<li>')
      .text( "#{count} #{label} " )
      .appendTo( '#tag_list' )

    del = $('<a href="javascript:void(0)">&times;</a>')
      .appendTo(li)
      .click ->
        li.remove()
        selected_items().each ->
          delete ($(@).data( 'tags' ))[id]
          delete ($(@).data( 'tags' ))[label]
          show_icons @
        save()

  redraw_tag_list = ->
    tags = {}
    selected = selected_items()
    selected.each ->
      for i, v of $(@).data( 'tags' )
        continue unless v
        tags[i] ||= 0
        tags[i] += 1
    $('#tag_list').empty()
    for tag_id, count of tags
      draw_tag $tags[tag_id], tag_id, count

    text = "#{selected.length} item"
    text += "s" if selected.length != 1
    $('#count').text( text )

  add_tag = (tag_id) ->
    selected_items().each ->
      $(@).data( 'tags' )[tag_id] = true
      show_icons @
    $('<div>').text( $tags[tag_id] ).appendTo( '#prev_match' )

  try_matches = (name) ->
    match = (str) ->
      for key, value of $tags
        continue unless value.toLowerCase() == name.toLowerCase()
        add_tag key
        return true

      for tag in $tag_order
        continue unless tag[0].toLowerCase().indexOf( str.toLowerCase() ) == 0
        add_tag tag[1]
        return true

      return false

    return if match name
    matched = false
    for str in name.split( /, ?/ )
      matched = true if match str

    return if matched
    matched = false
    for str in name.split( ' ' )
      matched = true if match str
    return if matched

    alert "No such tag"

  prev_tags = null

  apply_tags = ->
    name = $('#tags').val()
    $('#tags').val('')

    return true unless name

    # Create Event shortcut
    if name == 'eee'
      $('#tags').val('')
      create_event()
      return false

    if name == '.' && prev_tags
      name = prev_tags
    else
      prev_tags = name

    $('#prev_match').empty()

    try_matches(name)

    redraw_tag_list()
    save()
    false

  selection_start = null
  all.mousedown (e) ->
    return true unless advanced()
    return false unless e.which == 1
    if $('#tags').val()
      apply_tags()
      $('#prev_match').show()
    else
      $('#prev_match').hide()

    selection_start = @
    all.removeClass( 'selected' )
    $(@).addClass( 'selected' )
    redraw_tag_list()
    false

  all.mouseover ->
    return true unless advanced()
    return false unless selection_start
    all.removeClass( 'selected' )

    index_of = (arr, item) ->
      for i, elem of arr
        continue unless elem == item
        return +i
      null

    index = index_of all, @
    other = index_of all, selection_start

    if index > other
      tmp = other
      other = index
      index = tmp

    i = index
    while i <= other
      $(all[i]).addClass 'selected'
      i++

    redraw_tag_list()
    false

  $(window).mouseup (e) ->
    return true unless advanced()
    return false unless selection_start
    return false unless e.which == 1
    selection_start = null
    $('#tags').select().focus()
    false

  all.click ->
    return true unless advanced()
    false

  all.dblclick ->
    window.location = $(@).attr 'href'
    false

  $('#tags').keyup (e) ->
    return true unless e.which == 13 || e.which == 190 && $(@).val() == '.'

    $('#prev_match').hide()
    apply_tags()

  if $.cookies.get( 'cheese-advanced' ) == 'yes'
    $('#multi')[0].checked = true

  if advanced()
    $('.actions').show()
    $('.results').addClass 'shrink'
    $('.item a').each ->
      show_icons @

  $('#multi').click ->
    $('.actions').toggle()
    $('.results').toggleClass 'shrink'

    if advanced()
      $('.item a').each ->
        show_icons @
      $.cookies.set 'cheese-advanced', 'yes'
    else
      $('.icons').empty()
      $.cookies.del 'cheese-advanced'

  $('#download').click ->
    form = $('<form action="/item/download" method="post" />')
      .appendTo( document.body )

    ids = []
    selected_items().each ->
      ids.push $(@).attr('id')

    $('<input type="hidden" name="ids"/>')
      .val( ids.join(',') )
      .appendTo( form )

    form.submit()
