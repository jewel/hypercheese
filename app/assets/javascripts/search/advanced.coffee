update_advanced = ->
  return true

  query = []
  $('.tag').each ->
    return unless $(@).find( 'input:checked' ).length > 0
    query.push( $(@).data( 'label' ) )

  query = query.join ", "
  $.ajax
    url: '/search/update_advanced'
    type: 'GET'
    dataType: 'json'
    data:
      q: query
    success: (res) ->
      $('#count').text( res.count )
      $('.tag').each ->
        tag = res.tags[ $(@).data('id') ]
        $(@).toggle( tag > 0 )
        $(@).find( 'em' ).text( "(#{tag})" )

$ ->
  $('.tag').click ->
    update_advanced()
