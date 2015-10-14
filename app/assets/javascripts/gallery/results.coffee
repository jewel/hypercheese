@Results = React.createClass
  getInitialState: ->
    scrollTop: 0
    win_width: 100
    win_height: 100

  componentDidMount: ->
    @window = $('.scroll-window')
    @window[0].addEventListener 'scroll', @onScroll, false
    @window[0].addEventListener 'resize', @onResize, false
    @onResize()

  componentWillUnmount: ->
    @window[0].removeEventListener 'scroll', @onScroll, false
    @window[0].removeEventListener 'resize', @onResize, false

  onScroll: ->
    # Only redraw once we have scrolled past an entire row.  We overdraw so
    # that images will be fetched from the server before we need them, but we
    # don't want to rebuild our entire screen every scroll event, to save
    # battery.
    scrollTop = @window.scrollTop()
    if Math.abs( scrollTop - @state.scrollTop ) >= @rowHeight()
      @setState
        scrollTop: scrollTop

  onResize: ->
    @setState
      win_width: @window.width()
      win_height: @window.height()

  margin: 2

  imageSize: ->
    maxSize = 200
    minColumns = 3
    columnSize = ( maxSize + @margin * 2 ) * minColumns
    if @state.win_width < columnSize
      @state.win_width / minColumns - @margin * 2
    else
      maxSize

  rowHeight: ->
    @imageSize() + @margin * 2

  render: ->
    console.log 'rendering'

    margin = 2
    overdraw = 3
    maxSize = 200
    minColumns = 3

    imageWidth = @imageSize()
    imageHeight = @imageSize()
    rowHeight = @rowHeight()
    columnWidth = rowHeight

    imagesPerRow = Math.floor @state.win_width / columnWidth

    rowCount = Math.ceil @props.results.get('length') / imagesPerRow
    console.log @props.results.get('length')

    viewPortRowCount = Math.ceil @state.win_height / rowHeight + overdraw * 2

    viewPortStartRow = Math.floor @state.scrollTop / rowHeight - overdraw
    viewPortStartRow = 0 if viewPortStartRow < 0

    startIndex = viewPortStartRow * imagesPerRow
    endIndex = startIndex + viewPortRowCount * imagesPerRow

    # console.log "#{viewPortStartRow} * #{imagesPerRow} = #{startIndex}"
    # console.log "#{startIndex} + #{viewPortRowCount} * #{imagesPerRow} = #{endIndex}"

    # by calling 'objectAt', we will trigger a new AJAX request if the item
    # and its neighbors aren't already loaded
    items = []
    len = @props.results.get 'length'
    for i in [startIndex...endIndex]
      if i >= 0 && i < len
        item = @props.results.objectAt i
        items.push item

    viewPortStyle =
      top: "#{viewPortStartRow * rowHeight}px"

    resultsStyle =
      height: "#{rowHeight * rowCount}px"

    <div className="scroll-window">
      <div className="results" style={resultsStyle}>
        <div className="viewport" style={viewPortStyle}>
          {items.map((item) =>
            <Item imageWidth=imageWidth imageHeight=imageHeight key={item.get('id') || Math.random()} item={item}/>)
          }
        </div>
      </div>
    </div>
