@Details = React.createClass
  onClose: (e) ->
    @props.showItem null

  render: ->
    style =
      fontSize: '200px'

    <div className="details-window" style={style}>
      <a href="javascript:void(0)" onClick={@onClose}>&times;</a>
      <div>
        THIS IS IMAGE {@props.item_id} PLACE DETAILS
      </div>
      <img src="/images/loading.png"/>
    </div>
