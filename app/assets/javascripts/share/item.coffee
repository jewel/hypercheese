@Item = createReactClass
  onClick: (e) ->
    e.preventDefault()
    Store.navigate "/shares/#{Store.state.shareCode}/#{@props.item.id}"
    Store.needsRedraw()

  render: ->
    item = @props.item

    squareImage = Store.resizedURL 'square', item

    <button className="shared-item" key={item.id} onClick={@onClick}>
      <img src={squareImage} />
    </button>
