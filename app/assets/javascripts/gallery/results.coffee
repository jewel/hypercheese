@Results = React.createClass
  getInitialState: ->
    scrollTop: 0
    winWidth: null
    winHeight: null
    haveScrolled: false

  html: document.documentElement

  componentDidMount: ->
    window.addEventListener 'resize', @onResize, false
    window.addEventListener 'scroll', @onScroll, false

    # Normally we'd set these in getInitialState, but we don't know the values
    # until after the window exists.
    #
    # Note that onResize() sets the same properties, but we need them to exist
    # BEFORE the end of componentDidMount
    @state.winWidth = @html.clientWidth
    @state.winHeight = @html.clientHeight

    @onResize()
    @initialScroll()

  # We can either restore scroll position to its last known position, or we can
  # scroll to a specific item
  initialScroll: ->
    scrollTop = @props.scrollTop || 0
    if @props.highlight
      item = Store.getItem @props.highlight
      if item
        row = Math.floor item.index / @imagesPerRow()
        rowHeight = @rowHeight()
        # Put image's row right in middle of screen
        scrollTop = row * rowHeight - @state.winHeight / 2 + rowHeight / 2

    scrollTop = 0 if scrollTop < 0
    window.scroll 0, scrollTop

    @setState
      haveScrolled: true

  componentWillUnmount: ->
    window.removeEventListener 'resize', @onResize, false
    window.removeEventListener 'scroll', @onScroll, false

  onScroll: (e) ->
    # Only redraw once we have scrolled past an entire row.  We overdraw so
    # that images will be fetched from the server before we need them, but we
    # don't want to rebuild our entire screen every scroll event, to save
    # battery.
    scrollTop = window.pageYOffset
    @props.updateScrollTop scrollTop

    if Math.abs( scrollTop - @state.scrollTop ) >= @rowHeight()
      @setState
        scrollTop: scrollTop

  onResize: ->
    # clientWidth excludes the system scrollbar
    @setState
      winWidth: @html.clientWidth
      winHeight: @html.clientHeight

  # margin represents 1px of margin and 1px of image padding.  When used we
  # double it since it's on both sides of the image
  margin: 2
  tagboxHeight: 30

  # FIXME Instead of all the calculations in this method, we could have a hidden
  # but representative child that we query to find out what size we are.  It
  # would only need to be queried for resize events

  imageSize: ->
    maxSize = 200
    minColumns = 3
    columnSize = ( maxSize + @margin * 2 ) * minColumns
    if @state.winWidth < columnSize
      @state.winWidth / minColumns - @margin * 2
    else
      maxSize

  rowHeight: ->
    @imageSize() + @tagboxHeight + @margin * 2

  columnWidth: ->
    @imageSize() + @margin * 2

  imagesPerRow: ->
    Math.floor @state.winWidth / @columnWidth()

  render: ->
    if !@state.haveScrolled
      res =
        <div className="results" style={height: '10000000px'}>
        </div>
      return res

    overdraw = 3
    maxSize = 200
    minColumns = 3

    imageWidth = @imageSize()
    imageHeight = @imageSize()
    rowHeight = @rowHeight()
    columnWidth = @columnWidth()
    imagesPerRow = @imagesPerRow()

    scrollTop = @state.scrollTop

    viewPortRowCount = Math.ceil @state.winHeight / rowHeight + overdraw * 2 + 1
    viewPortStartRow = Math.floor scrollTop / rowHeight - overdraw
    viewPortStartRow = 0 if viewPortStartRow < 0

    totalItems = Store.state.resultCount

    if totalItems == null
      totalItems = viewPortRowCount * imagesPerRow

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
      <div className="viewport" style={viewPortStyle}>
        {
          items.map (item) =>
            <Item highlight={@props.highlight} imageWidth=imageWidth imageHeight=imageHeight key={item.index} item={item}/>
        }
      </div>
    </div>
