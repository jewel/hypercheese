$ ->
  $('.event').dblclick ->
    return true unless $('#multi')[0].checked

    div = $(@)

    name = prompt( "Rename event:", div.text() )
    return if name == null
    div.text 'Saving...'
    $.post '/event/rename/' + div.data( 'event_id' ),
      name: name
      (res) ->
        div.text( res )

  $('.event-subtitle').dblclick ->
    $(@).prev( '.event' ).dblclick()
