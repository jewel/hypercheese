@Details = React.createClass
  onClose: (e) ->
    @props.showItem null

  render: ->
    image_url = "/data/resized/large/#{@props.item_id}.jpg"
    <div className="details-window">
      <a href="javascript:void(0)" onClick={@onClose}>&times;</a>
      <img src={image_url}/>
    </div>
