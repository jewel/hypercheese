@Writer = createReactClass
  render: ->
    return null unless Store.canWrite()
    @props.children
