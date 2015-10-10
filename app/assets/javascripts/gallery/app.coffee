#= require ./navbar
#= require ./item

@GalleryApp = React.createClass
  getInitialState: ->
    tags: []
    items: []
    searchQuery: ""
    resultCount: 0
    scrollTop: $('.scroll-window').scrollTop()

  componentDidMount: ->
    @window = $('.scroll-window')
    @window[0].addEventListener 'scroll', @onScroll, false
    @window[0].addEventListener 'resize', @updateViewPort, false

    # FIXME we shouldn't need to wait for document.ready, but we don't know how
    # to get to ember's store until then.
    $ =>
      Bridge.init()
      Bridge.onChange (data) =>
        oldCount = @state.resultCount
        @setState data
        if oldCount != data.resultCount
          # viewport doesn't depend on data EXCEPT this data
          @updateViewPort()
      @updateViewPort()

  componentWillUnmount: ->
    @window[0].removeEventListener 'scroll', @onScroll, false
    @window[0].removeEventListener 'resize', @updateViewPort, false

  onScroll: ->
    # Only redraw once we have scrolled past an entire row.
    # We overdraw so that images will be fetched from the server before we need them, but we don't
    # want to rebuild our entire screen every scroll event, to save battery
    scrollTop = @window.scrollTop()
    if Math.abs( scrollTop - @state.scrollTop ) >= @state.rowHeight
      @updateViewPort()

  updateViewPort: ->
    console.log "updating viewport"
    win_width = @window.width()
    win_height = @window.height()
    scrollTop = @window.scrollTop()

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

    viewPortRowCount = Math.ceil win_height / rowHeight + overdraw * 2

    viewPortStartRow = Math.floor scrollTop / rowHeight - overdraw
    viewPortStartRow = 0 if viewPortStartRow < 0

    startIndex = viewPortStartRow * imagesPerRow
    endIndex = startIndex + viewPortRowCount * imagesPerRow

    # console.log "#{viewPortStartRow} * #{imagesPerRow} = #{startIndex}"
    # console.log "#{startIndex} + #{viewPortRowCount} * #{imagesPerRow} = #{endIndex}"


    @setState
      startIndex: startIndex
      endIndex: endIndex
      scrollTop: scrollTop
      viewPortStartRow: viewPortStartRow
      rowHeight: rowHeight
      rowCount: rowCount
      viewPortRowCount: viewPortRowCount
      imageWidth: imageSize
      imageHeight: imageSize

    Bridge.loadItems @state.searchQuery, startIndex, endIndex

  handleClick: (item) ->
    Bridge.store.find('item', item.id).then (item) =>
      item.set('isSelected', !item.get('isSelected'))
      Bridge.update()

    console.log "item clicked: ", item

  render: ->
    console.log 'rendering'

    viewPortStyle =
      top: "#{@state.viewPortStartRow * @state.rowHeight}px"

    resultsStyle =
      height: "#{@state.rowHeight * @state.rowCount}px"

    <div className="react-wrapper">
      <NavBar/>
      <div className="scroll-window">
        <div className="results" style={resultsStyle}>
          <div className="viewport" style={viewPortStyle}>
            {@state.items.map((item) =>
              <Item imageWidth=@state.imageWidth onClick={@handleClick.bind(@, item)} imageHeight=@state.imageHeight item={item}/>)
            }
          </div>
        </div>
      </div>
    </div>
