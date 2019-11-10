@ItemImg = createReactClass
  render: ->
    url = Store.resizedURL @props.size || "square", @props.id, @props.code
    <img src={url} />
