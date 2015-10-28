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
    newItem = Store.state.items[newIndex]
    if newItem
      image = new Image()
      image.src = "/data/resized/large/#{newItem.id}.jpg"

  moveTo: (dir) ->
    item = Store.state.itemsById[@props.item_id]
    if !item
      console.warn "Item not loaded: #{@props.item_id}"
      return

    newIndex = item.index + dir
    newItem = Store.state.items[newIndex]
    if newItem
      @props.showItem newItem.id

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
    style =
      fontSize: '35px'
    <div style={style} className="details-window">
      <div className="details-controls">
        <a href="javascript:void(0)" onClick={@onPrev}>prev</a>
        {' | '}
        <a href="javascript:void(0)" onClick={@onClose}>close</a>
        {' | '}
        <a href="javascript:void(0)" onClick={@onNext}>next</a>
      </div>
      <img className="detailed-image" src={image_url}/>
    </div>
