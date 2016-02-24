@QuickPreview = React.createClass
  onContextMenu: (e) ->
    # RMB ends up firing onContextMenu on us if we are created in the original
    # target's onMouseDown
    e.preventDefault()
    e.stopPropagation()

  onClose: (e) ->
    Store.state.quickPreview = null
    Store.forceUpdate()

  render: ->
    itemId = Store.state.quickPreview
    if itemId
      item = Store.getItem itemId

    <div className="quick-preview" onContextMenu={@onContextMenu} onMouseUp={@onClose}>
      {
        if item
          if item.variety == 'photo'
            <img src="/data/resized/large/#{itemId}.jpg"/>
          else if item.variety == 'video'
            <video src="/data/resized/stream/#{itemId}.mp4" autoPlay />
      }
    </div>
