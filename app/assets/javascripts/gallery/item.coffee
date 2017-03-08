@Item = React.createClass
  onClick: (e) ->
    if e.button == 0
      e.preventDefault()

      # Detect fake mouse clicks made by touch events
      fakeMouse = @lastTouchEvent && Date.now() - @lastTouchEvent < 500
      if fakeMouse && (Store.state.selectionCount > 0 || Store.state.selectMode)
        Store.toggleSelection @props.item.id

      else
        e.preventDefault()
        Store.navigate "/items/#{@props.item.id}"

  onMouseUp: (e) ->
    return unless e.button == 2

    if e.ctrlKey || e.metaKey
      if Store.state.selection[@props.item.id]
        Store.state.rangeStart = null
      else
        Store.state.rangeStart = @props.item.id
      Store.toggleSelection @props.item.id
    else if e.shiftKey
      Store.selectRange @props.item.id
    else if Store.state.selectMode
      Store.toggleSelection @props.item.id
    else
      Store.addPendingToSelection()
      Store.toggleSelection @props.item.id
      Store.state.rangeStart = @props.item.id

    null

  disableDefault: (e) ->
    e.preventDefault()
    null

  onMouseDown: (e) ->
    return unless e.button == 2

    fakeMouse = @lastTouchEvent && Date.now() - @lastTouchEvent < 1000
    # Ignore fake right-click from long press on touch devices
    return if fakeMouse

    Store.state.dragStart = @props.item.id
    Store.state.dragEnd = @props.item.id
    Store.state.dragLeftStart = false
    Store.dragRange()

  onMouseOver: (e) ->
    # Can't check e.button because it is not set in onMouseOver
    return unless Store.state.dragStart
    Store.state.dragEnd = @props.item.id
    if @props.item.id != Store.state.dragStart
      Store.state.dragLeftStart = true
    Store.dragRange()

  onTouchStart: (e) ->
    @lastTouchEvent = Date.now()
    return if e.touches.length != 1
    window.clearTimeout @touchTimer if @touchTimer
    @touchTimer = window.setTimeout @onTouchTimer, 500

  onTouchTimer: ->
    Store.toggleSelection @props.item.id
    Store.needsRedraw()

  onTouchMove: (e) ->
    @lastTouchEvent = Date.now()
    window.clearTimeout @touchTimer if @touchTimer

  onTouchEnd: (e) ->
    @lastTouchEvent = Date.now()
    window.clearTimeout @touchTimer if @touchTimer

  onContextMenu: (e) ->
    e.preventDefault()
    e.stopPropagation()
    return false

  render: ->
    item = @props.item
    selected = Store.state.selection[item.id]

    imageStyle =
      width: "#{@props.imageWidth}px"
      height: "#{@props.imageHeight}px"

    size = if @props.imageWidth > 400
      if item.variety == 'video'
        "exploded"
      else
        "large"
    else
      if @props.imageWidth > 200
        "s400"
      else if @props.imageWidth > 100
        "s200"
      else if @props.imageWidth > 50
        "s100"
      else
        "s50"

    if item.id?
      squareImage = "/data/resized/#{size}/#{item.id}.jpg"
    else
      squareImage = "/images/loading.png"

    classes = ["item"]
    classes.push 'selected' if selected
    classes.push 'dragging' if Store.state.dragging[item.id]
    classes.push 'highlight' if Store.state.highlight? && Store.state.highlight == item.id

    if @props.showTagbox
      used = {}
      tags = []
      if item.tag_ids
        for tagId in item.tag_ids
          tag = Store.state.tagsById[tagId]
          continue if !tag
          used[tagId] = true
          tags.push tag

      if selected
        for tag in Store.getPendingMatches()
          continue if used[tag.id]
          tags.push tag

      maxFit = @props.imageWidth / 33
      tagCount = tags.length
      numberToShow = maxFit
      numberToShow-- if item.has_comments
      if tagCount > numberToShow
        numberToShow--
      firstTags = tags.slice 0, numberToShow
      extraTags = tags.slice numberToShow
      extraTagsLabels = []
      for tagId in extraTags
        tag = Store.state.tagsById[tagId]
        if tag
          extraTagsLabels.push tag.label


    <div className={classes.join ' '} key="#{item.index}">
      <a href={"/items/#{@props.item.id}"} onClick={@onClick} onMouseDown={@onMouseDown} onMouseOver={@onMouseOver} onMouseUp={@onMouseUp} onTouchStart={@onTouchStart} onTouchMove={@onTouchMove} onTouchEnd={@onTouchEnd} onContextMenu={@onContextMenu}>
        <img className="thumb" style={imageStyle} src={squareImage} onMouseDown={@disableDefault} onContextMenu={@onContextMenu}/>
      </a>
      {
        if @props.showTagbox
          <div className="tagbox">
            {
              if item.has_comments
                <img src="/images/comment.png" key="comments"/>
            }
            {
              firstTags.map (tag) ->
                tagIconUrl = "/data/resized/s50/#{tag.icon}.jpg"
                if tag.icon == null
                  tagIconUrl = "/images/unknown-icon.png"
                c = ["tag-icon"]
                if !used[tag.id]
                  c.push 'new'
                <img title={tag.label} className={c.join ' '} key={tag.id} src={tagIconUrl}/>
            }
            {
              if extraTags.length > 0
                <div className="extra-tags" title={extraTagsLabels.join ', '} key="extras">{'+' + extraTags.length}</div>
            }
          </div>
      }
    </div>
