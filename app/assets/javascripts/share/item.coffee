@Item = createReactClass
  onClick: (e) ->
    e.preventDefault()
    Store.navigate "/shares/#{Store.state.shareCode}/#{@props.item.id}"
    Store.needsRedraw()

  render: ->
    item = @props.item

    squareImage = Store.resizedURL 'square', item

    <img key={item.id} className="shared-item" onClick={@onClick} src={squareImage} />
