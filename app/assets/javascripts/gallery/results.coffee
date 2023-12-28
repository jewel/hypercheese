@Results = createReactClass
  getInitialState: ->
    scrollTop: 0
    showScrollButton: false

  html: document.documentElement


  # users can let go of the mouse button when no longer over an item (most
  # commonly on the black space to the right, but also can be off screen)
  onMouseUp: (e) ->
    return unless e.button == 2
    return unless start = Store.state.dragStart
    Store.state.dragStart = null
    Store.state.dragging = {}
    Store.needsRedraw()

    return if start == Store.state.dragEnd && !Store.state.dragLeftStart
    e.preventDefault()

    value = true
    value = false if (e.metaKey || e.ctrlKey) && Store.state.selection[start]

    unless e.metaKey || e.ctrlKey || e.shiftKey
      Store.addPendingToSelection()

    # Use the end of the drag as the start of the next shift-click
    Store.state.rangeStart = Store.state.dragEnd
    Store.selectRange start, value
    null

  componentDidMount: ->
    window.addEventListener 'resize', @onResize, false
    window.addEventListener 'scroll', @onScroll, false
    window.addEventListener 'mouseup', @onMouseUp, false

  componentWillUnmount: ->
    window.removeEventListener 'resize', @onResize, false
    window.removeEventListener 'scroll', @onScroll, false
    window.removeEventListener 'mouseup', @onMouseUp, false
    window.clearTimeout @scrollButtonTimer if @scrollButtonTimer

  hideScrollButton: ->
    @scrollButtonTimer = null
    @setState
      showScrollButton: false

  onScroll: (e) ->
    # Only redraw once we have scrolled past an entire row.  We overdraw so
    # that images will be fetched from the server before we need them, but we
    # don't want to rebuild our entire screen every scroll event, to save
    # battery.
    scrollTop = window.pageYOffset

    if !@state.showScrollButton
      @setState
        showScrollButton: true

    window.clearTimeout @scrollButtonTimer if @scrollButtonTimer
    @scrollButtonTimer = window.setTimeout @hideScrollButton, 2000

    if Math.abs( scrollTop - @state.scrollTop ) >= @rowHeight()
      @setState
        scrollTop: scrollTop

  onResize: ->
    Store.needsRedraw()

  # margin represents 1px of margin and 1px of image padding.  When used we
  # double it since it's on both sides of the image
  margin: 2

  imageSize: ->
    size = Math.round(1.3 ** (Store.state.zoom - 5) * 100)

    # Resize larger to fit perfectly on page
    imagesPerRow = Math.floor(@html.clientWidth / size)
    res = Math.floor(@html.clientWidth / imagesPerRow) - @margin * 2
    res

  tagboxHeight: ->
    if @imageSize() < 150
      0
    else
      30

  rowHeight: ->
    @imageSize() + @tagboxHeight() + @margin * 2

  columnWidth: ->
    @imageSize() + @margin * 2

  imagesPerRow: ->
    Math.floor @html.clientWidth / @columnWidth()


  spinner: ->
    <div style={textAlign: 'center', margin: 48}>
      <i className="fa fa-spinner fa-spin" style={fontSize: 48}/>
    </div>

  render: ->
    if Store.state.searching && !Store.state.searchKey
      return @spinner()

    overdraw = 3
    maxSize = 200
    minColumns = 3

    imageWidth = @imageSize()
    imageHeight = @imageSize()
    rowHeight = @rowHeight()
    columnWidth = @columnWidth()
    imagesPerRow = @imagesPerRow()

    scrollTop = @state.scrollTop

    viewPortRowCount = Math.ceil @html.clientHeight / rowHeight + overdraw * 2 + 1
    viewPortStartRow = Math.floor scrollTop / rowHeight - overdraw
    viewPortStartRow = 0 if viewPortStartRow < 0

    showTagbox = @tagboxHeight() != 0

    totalItems = Store.state.resultCount

    if totalItems == null
      totalItems = 0

    rowCount = Math.ceil totalItems / imagesPerRow

    startIndex = viewPortStartRow * imagesPerRow
    endIndex = startIndex + viewPortRowCount * imagesPerRow - 1
    startIndex = totalItems - 1 if startIndex >= totalItems
    endIndex = totalItems - 1 if endIndex >= totalItems

    # console.log "#{viewPortStartRow} * #{imagesPerRow} = #{startIndex}"
    # console.log "#{startIndex} + #{viewPortRowCount} * #{imagesPerRow} - 1 = #{endIndex}"

    items = []
    for i in [startIndex..endIndex]
      itemId = Store.state.items[i]
      item = null
      if itemId
        item = Store.getItem itemId
      item ||=
        id: null
        index: i
      items.push item

    items = [] if totalItems == 0

    viewPortStyle =
      top: "#{viewPortStartRow * rowHeight}px"

    windowHeight = rowHeight * rowCount

    resultsStyle =
      height: "#{windowHeight}px"

    # Now that we know exactly how many records we need, we ask for them to be
    # fetched.  When the results come back, they will cause a re-render
    Store.executeSearch startIndex, endIndex

    <div className="results" style={resultsStyle}>
      <ScrollButton height={windowHeight} top={scrollTop} visible={@state.showScrollButton}/>
      <div className="viewport" style={viewPortStyle}>
        {
          items.map (item) =>
            <Item showTagbox={showTagbox} imageWidth={imageWidth} imageHeight={imageHeight} key={item.index} item={item}/>
        }
      </div>
    </div>
