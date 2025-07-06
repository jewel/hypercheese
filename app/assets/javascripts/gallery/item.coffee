component 'Item', ({item, imageWidth, imageHeight, showTagbox}) ->
  [lastTouchEvent, setLastTouchEvent] = useState null
  [touchTimer, setTouchTimer] = useState null

  onClick = (e) ->
    if e.button == 0
      e.preventDefault()

      # Detect fake mouse clicks made by touch events
      fakeMouse = lastTouchEvent && Date.now() - lastTouchEvent < 500
      if fakeMouse && (Store.state.selectionCount > 0 || Store.state.selectMode)
        Store.toggleSelection item.id
      else
        e.preventDefault()
        Store.navigate "/items/#{item.id}"

  onMouseUp = (e) ->
    return unless e.button == 2

    if e.ctrlKey || e.metaKey
      if Store.state.selection[item.id]
        Store.state.rangeStart = null
      else
        Store.state.rangeStart = item.id
      Store.toggleSelection item.id
    else if e.shiftKey
      Store.selectRange item.id
    else if Store.state.selectMode
      Store.toggleSelection item.id
    else
      Store.addPendingToSelection()
      Store.toggleSelection item.id
      Store.state.rangeStart = item.id

    null

  disableDefault = (e) ->
    e.preventDefault()
    null

  onMouseDown = (e) ->
    return unless e.button == 2

    fakeMouse = lastTouchEvent && Date.now() - lastTouchEvent < 1000
    # Ignore fake right-click from long press on touch devices
    return if fakeMouse

    Store.state.dragStart = item.id
    Store.state.dragEnd = item.id
    Store.state.dragLeftStart = false
    Store.dragRange()

  onMouseOver = (e) ->
    # Can't check e.button because it is not set in onMouseOver
    return unless Store.state.dragStart
    Store.state.dragEnd = item.id
    if item.id != Store.state.dragStart
      Store.state.dragLeftStart = true
    Store.dragRange()

  onTouchStart = (e) ->
    setLastTouchEvent Date.now()
    return if e.touches.length != 1
    window.clearTimeout touchTimer if touchTimer
    setTouchTimer window.setTimeout onTouchTimer, 500

  onTouchTimer = ->
    Store.toggleSelection item.id
    Store.needsRedraw()

  onTouchMove = (e) ->
    setLastTouchEvent Date.now()
    window.clearTimeout touchTimer if touchTimer

  onTouchEnd = (e) ->
    setLastTouchEvent Date.now()
    window.clearTimeout touchTimer if touchTimer

  onContextMenu = (e) ->
    e.preventDefault()
    e.stopPropagation()
    return false

  selected = Store.state.selection[item.id]

  imageStyle =
    width: "#{imageWidth}px"
    height: "#{imageHeight}px"

  size = if imageWidth > 400
    if item.variety == 'video'
      "exploded"
    else
      "large"
  else
    "square"

  if item.id?
    squareImage = Store.resizedURL size, item
  else
    squareImage = "/images/loading.png"

  classes = if Store.state.shareMode then ["shared-item"] else ["item"]
  classes.push 'selected' if selected
  classes.push 'dragging' if Store.state.dragging[item.id]
  classes.push 'highlight' if Store.state.highlight? && Store.state.highlight == item.id

  if showTagbox && !Store.state.shareMode
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

    maxFit = imageWidth / 33
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
        extraTagsLabels.push(tag.alias || tag.label)

  itemUrl = if Store.state.shareMode then "/shares/#{Store.state.shareCode}/#{item.id}" else "/items/#{item.id}"

  <div className={classes.join ' '} key="#{item.index}">
    <a href={itemUrl} onClick={onClick} onMouseDown={onMouseDown} onMouseOver={onMouseOver} onMouseUp={onMouseUp} onTouchStart={onTouchStart} onTouchMove={onTouchMove} onTouchEnd={onTouchEnd} onContextMenu={onContextMenu}>
      <img className="thumb" style={imageStyle} src={squareImage} onMouseDown={disableDefault} onContextMenu={onContextMenu}/>
    </a>
    {
      if showTagbox && !Store.state.shareMode
        <div className="tagbox">
          {
            if item.has_comments
              <img src="/images/comment.png" key="comments"/>
          }
          {
            firstTags.map (tag) ->
              tagIconUrl = Store.resizedURL 'square', tag.icon_id, tag.icon_code
              c = ["tag-icon"]
              if !used[tag.id]
                c.push 'new'
              <img title={tag.alias || tag.label} className={c.join ' '} key={tag.id} src={tagIconUrl}/>
          }
          {
            if extraTags.length > 0
              <div className="extra-tags" title={extraTagsLabels.join ', '} key="extras">{'+' + extraTags.length}</div>
          }
        </div>
    }
  </div>
