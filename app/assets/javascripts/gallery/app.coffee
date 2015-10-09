#= require ./navbar

@GalleryApp = React.createClass
  getInitialState: ->
    tags: []
    items: []
    searchQuery: ""
    resultCount: 0
    scrollTop: $(window).scrollTop()

  componentDidMount: ->
    window.addEventListener 'scroll', @onScroll, false
    window.addEventListener 'resize', @updateViewport, false

    @window = $(window)

    $ =>
      Bridge.init()
      Bridge.onChange (data) =>
        @setState data
      @updateViewPort()

  componentWillUnmount: ->
    window.removeEventListener 'scroll', @onScroll, false
    window.removeEventListener 'resize', @updateViewport, false

  onScroll: ->
    scrollTop = @window.scrollTop()
    viewPortTop = @state.viewPortStartRow * @state.rowHeight
    viewPortSize = @state.viewPortRowCount * @state.rowHeight
    if scrollTop < viewPortTop || scrollTop > viewPortTop + viewPortSize - @window.height()
      updateViewPort()

  updateViewPort: ->
    console.log "updating viewport"
    win = @window
    win_width = win.width()
    win_height = win.height()

    margin = 2
    overdraw = 3
    scrollbarWidth = 14
    maxSize = 200
    minColumns = 3

    columnSize = ( maxSize + margin * 2 ) * minColumns
    if win_width >= columnSize
      imageSize = maxSize
    else
      win_width / minColumns - margin * 2

    columnWidth = imageSize + margin * 2
    rowHeight = imageSize + margin * 2

    imagesPerRow = Math.floor win_width / columnWidth

    rowCount = Math.ceil @state.resultCount / imagesPerRow

    toolbarHeight = 52
    scrollPos = win.scrollTop() - toolbarHeight
    viewPortRowCount = Math.ceil win_height / rowHeight + overdraw * 2

    viewPortStartRow = Math.floor scrollPos / rowHeight - overdraw
    viewPortStartRow = 0 if viewPortStartRow < 0

    startIndex = viewPortStartRow * imagesPerRow
    endIndex = startIndex + viewPortRowCount * imagesPerRow

    # console.log "#{viewPortStartRow} * #{imagesPerRow} = #{startIndex}"
    # console.log "#{startIndex} + #{viewPortRowCount} * #{imagesPerRow} = #{endIndex}"

    @setState
      startIndex: startIndex
      endIndex: endIndex
      viewPortStartRow: viewPortStartRow
      rowHeight: rowHeight
      rowCount: rowCount
      viewPortRowCount: viewPortRowCount
      width: imageSize
      height: imageSize

    Bridge.loadItems @state.searchQuery, startIndex, endIndex

  render: ->
    console.log 'rendering'
    image = (item, pos) =>
      unless item?
        item = {}

      imageStyle =
        width: "#{@state.imageWidth}px"
        height: "#{@state.imageHeight}px"

      bgColor = if item.isSelected
        "blue"
      else
        item.bgcolor

      bgStyle =
        "backgroundColor": bgColor

      if item.id?
        squareImage = "/data/resized/square/#{item.id}.jpg"
      else
        squareImage = "/images/loading.png"

      selected = if item.isSelected then 'selected' else ''
      <div className="item" style={bgStyle} key="item_#{item.id || Math.random()}">
        <img className="thumb #{selected}" style={imageStyle} src={squareImage}/>
      </div>

    viewPortStyle =
      top: "#{@state.viewPortStartRow * @state.rowHeight}px"

    resultsStyle =
      height: "#{@state.rowHeight * @state.rowCount}px"

    <div>
      <NavBar/>
      <div className="scroll-window">
        <div className="results" style={resultsStyle}>
          <div className="viewport" style={viewPortStyle}>
            {@state.items.map(image)}
          </div>
        </div>
      </div>
    </div>
