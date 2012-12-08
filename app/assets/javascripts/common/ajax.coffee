$ ->
  $('#spinner')
  .ajaxStart ->
    $(@).show()
  .ajaxStop ->
    $(@).hide()

  $.ajaxSetup
    error: (x,e) ->
      switch x.status
        when 0
          alert 'Error: you are offline'
          return
        when 404
          alert 'Error: URL not found'
          return
        when 500
          alert 'Error: Internal Server Error'
          return
      switch e
        when 'parsererror'
          alert 'Error: JSON parse problem'
          return
        when 'timeout'
          alert 'Error: Request timed out'
          return
        else
          alert 'Unknown error'
          return
