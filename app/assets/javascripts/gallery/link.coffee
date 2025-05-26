component 'Link', ({onClick: propOnClick, href, children, ...props}) ->
  onClick = (e) ->
    document.body.scrollTo 0, 0

    if propOnClick
      propOnClick e

    if e.button == 0
      e.preventDefault()
      Store.navigate href

  attrs = {onClick, href, ...props}

  React.createElement "a", attrs, children
