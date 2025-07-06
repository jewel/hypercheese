@Item = createReactClass
  onClick: (e) ->
    e.preventDefault()
    Store.navigate "/shares/#{Store.state.shareCode}/#{@props.item.id}"
    Store.needsRedraw()

  render: ->
    item = @props.item

    squareImage = Store.resizedURL 'square', item

    imageStyle = {}
    if item.rotate
      imageStyle.transform = "rotate(#{item.rotate}deg)"

    <button className="shared-item" key={item.id} onClick={@onClick}>
      <img style={imageStyle} src={squareImage} />
    </button>
