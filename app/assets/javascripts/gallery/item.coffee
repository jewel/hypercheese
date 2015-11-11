@Item = React.createClass
  onSelect: (e) ->
    if e.ctrlKey || e.shiftKey
      e.stopPropagation()
      return @onClick(e)

    e.stopPropagation()
    if Store.state.selection[@props.item.id]
      Store.state.rangeStart = null
    else
      Store.state.rangeStart = @props.item.id
    Store.toggleSelection @props.item.id

  onClick: (e) ->
    if e.ctrlKey
      e.preventDefault()
      if Store.state.selection[@props.item.id]
        Store.state.rangeStart = null
      else
        Store.state.rangeStart = @props.item.id
      Store.toggleSelection @props.item.id
    else if e.shiftKey
      e.preventDefault()
      Store.selectRange @props.item.id
    else if Store.state.selecting
      e.preventDefault()
      Store.toggleSelection @props.item.id

    true

  disableDefault: (e) ->
    e.preventDefault()
    null

  onMouseDown: (e) ->
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

  render: ->
    item = @props.item
    selected = Store.state.selection[item.id]

    imageStyle =
      width: "#{@props.imageWidth}px"
      height: "#{@props.imageHeight}px"

    size = if @props.imageWidth > 400
      "large"
    else
      "square"

    if item.id?
      squareImage = "/data/resized/#{size}/#{item.id}.jpg"
    else
      squareImage = "/images/loading.png"

    classes = ["item"]
    classes.push 'selected' if selected
    classes.push 'selecting' if Store.state.selecting
    classes.push 'dragging' if Store.state.dragging[item.id]
    classes.push 'highlight' if Store.state.highlight? && Store.state.highlight == item.id

    maxFit = @props.imageWidth / 33
    tags = item.tag_ids || []
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
      <a href={"#/items/#{@props.item.id}"} onClick={@onClick} onMouseDown={@onMouseDown} onMouseOver={@onMouseOver} onMouseUp={@onMouseUp}>
        <img className="thumb" style={imageStyle} src={squareImage} onMouseDown={@disableDefault}/>
      </a>
      {
        if @props.imageWidth >= 120 || selected || Store.state.selecting
          <a href="javascript:void(0)" onClick={@onSelect} className="checkmark">
            {
              if selected
                <i className="fa fa-check-square-o"/>
              else
                <i className="fa fa-square-o"/>
            }
          </a>
      }
      {
        if @props.showTagbox
          <div className="tagbox">
            {
              if item.has_comments
                <img src="/images/comment.png" key="comments"/>
            }
            {
              firstTags.map (tagId) ->
                tag = Store.state.tagsById[tagId]
                if tag
                  tagIconUrl = "/data/resized/square/#{tag.icon}.jpg"
                  <img title={tag.label} className="tag-icon" key={tagId} src={tagIconUrl}/>
            }
            {
              if extraTags.length > 0
                <div className="extra-tags" title={extraTagsLabels.join ', '} key="extras">{'+' + extraTags.length}</div>
            }
          </div>
      }
    </div>
