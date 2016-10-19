@Link = React.createClass
  onClick: (e) ->
    if e.button == 0
      e.preventDefault()
      console.log "Going to #{@props.href}!"

  render: ->
    attrs = {}
    Object.assign attrs, @props
    delete attrs.children
    attrs.onClick = @onClick

    React.createElement "a", attrs, @props.children
