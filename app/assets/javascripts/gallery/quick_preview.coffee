@QuickPreview = React.createClass

  onContextMenu: (e) ->
    e.preventDefault()
    e.stopPropagation()

  onMouseUp: (e) ->
    Store.state.quickPreview = null
    Store.forceUpdate()

  render: ->
    itemId = Store.state.quickPreview
    if itemId
      item = Store.getItem itemId

    <div className="quick-preview" onContextMenu={@onContextMenu} onMouseUp={@onMouseUp}>
      {
        if item
          if item.variety == 'photo'
            <img src="/data/resized/large/#{itemId}.jpg"/>
          else if item.variety == 'video'
            <video poster="/data/resized/large/#{itemId}.jpg" src="/data/resized/stream/#{itemId}.mp4" autoPlay />
      }
    </div>
