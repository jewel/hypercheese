@Item = React.createClass
  componentDidMount: ->
    @clickUndo1 = null
    @clickUndo2 = null

  onClick: (e) ->
    # Detect fake mouse clicks made by touch events
    fakeMouse = @lastTouchEvent && Date.now() - @lastTouchEvent < 500

    if !fakeMouse
      @clickUndo1 = @clickUndo2
      @clickUndo2 = [$.extend({}, Store.state.selection), Store.state.selectionCount]

    if e.ctrlKey || e.metaKey
      e.preventDefault()
      if Store.state.selection[@props.item.id]
        Store.state.rangeStart = null
      else
        Store.state.rangeStart = @props.item.id
      Store.toggleSelection @props.item.id
    else if e.shiftKey
      e.preventDefault()
      Store.selectRange @props.item.id
    else if Store.state.selectMode || fakeMouse && Store.state.selectionCount > 0
      e.preventDefault()
      Store.toggleSelection @props.item.id
    else if !fakeMouse
      e.preventDefault()
      Store.addPendingToSelection()
      Store.toggleSelection @props.item.id

    null

  # On all browsers but IE, a double click is proceeded by two click
  # events.  Revert state to how it was two clicks ago.
  onDoubleClick: (e) ->
    if @clickUndo1
      Store.state.selection = @clickUndo1[0]
      Store.state.selectionCount = @clickUndo1[1]

    Store.navigate "/items/#{@props.item.id}"

  disableDefault: (e) ->
    e.preventDefault()
    null

  onMouseDown: (e) ->
    if e.button == 2
      e.preventDefault()
      e.stopPropagation()
      Store.state.quickPreview = @props.item.id
      Store.forceUpdate()

    return unless e.button == 0
    Store.state.dragStart = @props.item.id
    Store.state.dragEnd = @props.item.id
    Store.state.dragLeftStart = false
    Store.dragRange()

  onMouseOver: (e) ->
    return unless e.button == 0
    return unless Store.state.dragStart
    Store.state.dragEnd = @props.item.id
    if @props.item.id != Store.state.dragStart
      Store.state.dragLeftStart = true
    Store.dragRange()

  onMouseUp: (e) ->

  onTouchStart: (e) ->
    return if Store.state.selectionCount > 0
    return if e.touches.length != 1
    window.clearTimeout @touchTimer if @touchTimer
    @touchTimer = window.setTimeout @onTouchTimer, 500

  onTouchTimer: ->
    @lastTouchEvent = Date.now()
    return if Store.state.selectionCount > 0
    Store.toggleSelection @props.item.id
    Store.forceUpdate()

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
      "square"

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
      <a href={"#/items/#{@props.item.id}"} onClick={@onClick} onDoubleClick={@onDoubleClick} onMouseDown={@onMouseDown} onMouseOver={@onMouseOver} onMouseUp={@onMouseUp} onTouchStart={@onTouchStart} onTouchMove={@onTouchMove} onTouchEnd={@onTouchEnd} onContextMenu={@onContextMenu}>
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
                tagIconUrl = "/data/resized/square/#{tag.icon}.jpg"
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
