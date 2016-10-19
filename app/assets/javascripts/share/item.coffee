@Item = React.createClass
  onClick: ->
    Store.state.showItem = @props.item
    Store.needsRedraw()

  render: ->
    item = @props.item

    squareImage = "/data/resized/square/#{item.id}.jpg"

    <a className="shared-item" key={item.id} href="javascript:void(0)" onClick={@onClick}>
      <img src={squareImage} />
    </a>
