@Results = React.createClass
  getInitialState: ->
    scrollTop: null
    win_width: 1000
    win_height: 700

  componentDidMount: ->
    @window = $('.scroll-window')[0]
    @window.addEventListener 'scroll', @onScroll, false
    window.addEventListener 'resize', @onResize, false
    @onResize()

  componentWillUnmount: ->
    @window.removeEventListener 'scroll', @onScroll, false
    window.removeEventListener 'resize', @onResize, false

  onScroll: ->
    # Only redraw once we have scrolled past an entire row.  We overdraw so
    # that images will be fetched from the server before we need them, but we
    # don't want to rebuild our entire screen every scroll event, to save
    # battery.
    scrollTop = @window.scrollTop
    if Math.abs( scrollTop - @state.scrollTop ) >= @rowHeight()
      @setState
        scrollTop: scrollTop

  onResize: ->
    # clientWidth excludes the system scrollbar
    @setState
      win_width: @window.clientWidth
      win_height: @window.clientHeight

  # margin represents 1px of margin and 1px of image padding.  When used we
  # double it since it's on both sides of the image
  margin: 2
  tagboxHeight: 30

  imageSize: ->
    maxSize = 200
    minColumns = 3
    columnSize = ( maxSize + @margin * 2 ) * minColumns
    if @state.win_width < columnSize
      @state.win_width / minColumns - @margin * 2
    else
      maxSize

  rowHeight: ->
    @imageSize() + @tagboxHeight + @margin * 2

  columnWidth: ->
    @imageSize() + @margin * 2

  render: ->
    overdraw = 3
    maxSize = 200
    minColumns = 3

    imageWidth = @imageSize()
    imageHeight = @imageSize()
    rowHeight = @rowHeight()
    columnWidth = @columnWidth()

    imagesPerRow = Math.floor @state.win_width / columnWidth

    scrollTop = @state.scrollTop
    scrollTop = 0 unless scrollTop

    viewPortRowCount = Math.ceil @state.win_height / rowHeight + overdraw * 2
    viewPortStartRow = Math.floor scrollTop / rowHeight - overdraw
    viewPortStartRow = 0 if viewPortStartRow < 0

    totalItems = Store.state.resultCount

    if totalItems == null
      totalItems = viewPortRowCount * imagesPerRow

    rowCount = Math.ceil totalItems / imagesPerRow

    startIndex = viewPortStartRow * imagesPerRow
    endIndex = startIndex + viewPortRowCount * imagesPerRow
    endIndex = totalItems - 1 if endIndex >= totalItems

    # console.log "#{viewPortStartRow} * #{imagesPerRow} = #{startIndex}"
    # console.log "#{startIndex} + #{viewPortRowCount} * #{imagesPerRow} = #{endIndex}"

    items = []
    for i in [startIndex..endIndex]
      item = Store.state.items[i]
      item ||=
        id: null
        index: i
      items.push item

    viewPortStyle =
      top: "#{viewPortStartRow * rowHeight}px"

    resultsStyle =
      height: "#{rowHeight * rowCount}px"

    # Now that we know exactly how many records we need, we ask for them to be
    # fetched.  When the results come back, they will cause a re-render
    Store.executeSearch startIndex, endIndex

    <div className="scroll-window">
      <div className="results" style={resultsStyle}>
        <div className="viewport" style={viewPortStyle}>
          {items.map((item) =>
            <Item imageWidth=imageWidth imageHeight=imageHeight key={item.index} item={item}/>)
          }
        </div>
      </div>
    </div>
