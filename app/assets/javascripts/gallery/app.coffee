#= require ./navbar

@GalleryApp = React.createClass
  getInitialState: ->
    items: {}
    tags: {}
    searchQuery: ""
    resultCount: 0
    scrollTop: $(window).scrollTop()

  componentDidMount: ->
    window.addEventListener 'scroll', @onScroll, false
    $.ajax
      url: "/tags"
      dataType: "json"
      success: (res) =>
        @setState
          tags: res.tags

    @executeSearch(0)

  componentWillUnmount: ->
    window.removeEventListener 'scroll', @onScroll, false

  onScroll: ->
    # FIXME We need to throttle these events
    @setState
      scrollTop: $(window).scrollTop()

  executeSearch: (position) ->
    return if @searching
    @searching = true

    limit = 20

    $.ajax
      url: "/items"
      dataType: "json"
      data:
        limit: limit
        offset: position
        query: @state.searchQuery
      success: (res) =>
        @searching = false
        @setState
          resultCount: res.meta.total
          items: @injectItems( res.items, position )
      complete: =>
        @searching = false

  injectItems: (items, pos) ->
    newItems = @shallowCopyItems()

    i = 0
    while i < items.length
      items[i].position = pos + i
      newItems[pos + i] = items[i]
      i++

    newItems

  shallowCopyItems: ->
    $.extend {}, @state.items

  updateItem: (item) ->
    newItems = @shallowCopyItems()
    newItems[item.position] = item

    @setState
      items: newItems

  viewPortItems: (startIndex, endIndex) ->
    items = []

    for i in [startIndex...endIndex]
      continue if i < 0 || i >= @state.resultCount
      item = @state.items[i]
      @executeSearch(i) unless item
      items.push item

    items

  zoomed: false

  render: ->
    console.log "redrawing"
    win = $(window)
    win_width = win.width()
    win_height = win.height()

    margin = 2
    overdraw = 3
    scrollbarWidth = 14
    maxSquareSize = 200
    minColumns = 3

    columnSize = ( maxSquareSize + margin * 2 ) * minColumns
    if win_width >= columnSize
      imageSquareSize = maxSquareSize
    else
      win_width / minColumns - margin * 2

    if @zoomed
      maxImageWidth = win_width - margin * 2 - scrollbarWidth
      maxImageHeight = win_height - margin * 2
    else
      maxImageWidth = imageSquareSize
      maxImageHeight = imageSquareSize

    columnWidth = maxImageWidth + margin * 2
    rowHeight = maxImageHeight + margin * 2


    imagesPerRow = Math.floor win_width / columnWidth
    imagesPerRow = 1 if @zoomed

    rowCount = Math.ceil @state.resultCount / imagesPerRow

    resultsClass = if @zoomed
      "results zoomed"
    else
      "results"
    resultsStyle =
      height: "#{rowHeight * rowCount}px"
    toolbarHeight = 52
    scrollPos = win.scrollTop() - toolbarHeight
    viewPortRowCount = Math.ceil win_height / rowHeight + overdraw * 2

    viewPortStartRow = Math.floor scrollPos / rowHeight - overdraw
    viewPortStartRow = 0 if viewPortStartRow < 0

    viewPortStyle =
      top: "#{viewPortStartRow * rowHeight}px"

    startIndex = viewPortStartRow * imagesPerRow
    endIndex = startIndex + viewPortRowCount * imagesPerRow
    viewPortItems = @viewPortItems startIndex, endIndex

    # console.log "#{viewPortStartRow} * #{imagesPerRow} = #{startIndex}"
    # console.log "#{startIndex} + #{viewPortRowCount} * #{imagesPerRow} = #{endIndex}"


    image = (item) =>
      unless item?
        item =
          width: 100
          height: 100
          bgColor: "#808080"

      if @zoomed
        target_width = maxImageWidth
        target_height = maxImageHeight
        width = item.width
        height = item.height

        if width > target_width
          height *= target_width / width
          width *= target_width / width

        if height > target_height
          width *= target_height / height
          height *= target_height / height

        margin = 0
        if target_height > height
          margin = Math.floor( (target_height - height) / 2)
        imageStyle =
          width: "#{Math.floor(width)}px"
          height: "#{Math.floor(height)}px"
          marginTop: "#{margin}px"
          marginBottom: "#{margin}px"
      else
        imageStyle =
          width: "#{maxImageWidth}px"
          height: "#{maxImageHeight}px"

      bgColor = if item.isSelected
        "blue"
      else
        if @zoomed
          "black"
        else
          item.bgcolor

      bgStyle =
        backgroundColor: bgColor

      imageSize = if @zoomed then 'large' else 'square'

      if item.id?
        squareImage = "/data/resized/#{imageSize}/#{item.id}.jpg"
      else
        squareImage = "/assets/loading.png"

      selected = if item.isSelected then 'selected' else ''
      <div className="item" style={bgStyle} key="item_#{item.id || Math.random()}">
        <img className="thumb #{selected}" style={imageStyle} src={squareImage}/>
      </div>

    <div>
      <NavBar/>
      <div className={resultsClass} style={resultsStyle}>
        <div className="viewport" style={viewPortStyle}>
          {viewPortItems.map(image)}
        </div>
      </div>
    </div>
