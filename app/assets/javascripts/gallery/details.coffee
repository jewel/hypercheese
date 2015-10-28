@Details = React.createClass
  onClose: ->
    @props.showItem null

  onNext: ->
    @moveTo 1

  onPrev: ->
    @moveTo -1

  preload: (dir) ->
    item = Store.state.itemsById[@props.item_id]
    if !item
      console.warn "Item not loaded: #{@props.item_id}"
      return

    newIndex = item.index + dir
    newItemId = Store.state.items[newIndex]
    if newItemId
      image = new Image()
      image.src = "/data/resized/large/#{newItemId}.jpg"

  moveTo: (dir) ->
    item = Store.state.itemsById[@props.item_id]
    if !item
      console.warn "Item not loaded: #{@props.item_id}"
      return

    newIndex = item.index + dir
    newItemId = Store.state.items[newIndex]
    if newItem
      @props.showItem newItemId

  render: ->
    # load prev and next indexes
    item = Store.state.itemsById[@props.item_id]
    if !item
      console.warn "Item not loaded: #{@props.item_id}"
      return

    # make sure that the next batch is loaded if they are a fast clicker
    margin = 10

    Store.executeSearch item.index - margin, item.index + margin
    @preload 1
    @preload -1

    image_url = "/data/resized/large/#{@props.item_id}.jpg"
    <div className="details-window">
      <a className="control prev-control" href="javascript:void(0)" onClick={@onPrev}>&larr;</a>
      <a className="control close-control" href="javascript:void(0)" onClick={@onClose}></a>
      <a className="control next-control" href="javascript:void(0)" onClick={@onNext}>&rarr;</a>
      <img className="detailed-image" src={image_url}/>
    </div>
