@Item = createReactClass
  onClick: (e) ->
    e.preventDefault()
    Store.navigate "/shares/#{Store.state.shareCode}/#{@props.item.id}"
    Store.needsRedraw()

  render: ->
    item = @props.item

    squareImage = Store.resizedURL 'square', item

    <a className="shared-item" key={item.id} href="javascript:void(0)" onClick={@onClick}>
      <img src={squareImage} />
    </a>
