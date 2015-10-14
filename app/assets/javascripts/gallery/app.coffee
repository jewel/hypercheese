#= require ./navbar
#= require ./item

@GalleryApp = React.createClass
  getInitialState: ->
    tags: []
    viewPortItems: []
    searchQuery: ""
    results: Ember.Object.create()
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
        @updateViewPort(data)
      @updateViewPort()

  componentWillUnmount: ->
    @window[0].removeEventListener 'scroll', @onScroll, false
    @window[0].removeEventListener 'resize', @updateViewPort, false

  onScroll: ->
    # Only redraw once we have scrolled past an entire row.  We overdraw so
    # that images will be fetched from the server before we need them, but we
    # don't want to rebuild our entire screen every scroll event, to save
    # battery.
    scrollTop = @window.scrollTop()
    if Math.abs( scrollTop - @state.scrollTop ) >= @state.rowHeight
      @updateViewPort()

  updateViewPort: (data) ->
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

    rowCount = Math.ceil @state.results.get('length') / imagesPerRow

    viewPortRowCount = Math.ceil win_height / rowHeight + overdraw * 2

    viewPortStartRow = Math.floor scrollTop / rowHeight - overdraw
    viewPortStartRow = 0 if viewPortStartRow < 0

    startIndex = viewPortStartRow * imagesPerRow
    endIndex = startIndex + viewPortRowCount * imagesPerRow

    # console.log "#{viewPortStartRow} * #{imagesPerRow} = #{startIndex}"
    # console.log "#{startIndex} + #{viewPortRowCount} * #{imagesPerRow} = #{endIndex}"

    # by calling 'objectAt', we will trigger a new AJAX request if the item
    # and its neighbors aren't already loaded
    items = []
    len = @state.results.get 'length'
    for i in [startIndex...endIndex]
      if i >= 0 && i < len
        item = @state.results.objectAt i
        items.pushObject item
    items

    data ||= {}
    data.startIndex = startIndex
    data.endIndex = endIndex
    data.scrollTop = scrollTop
    data.viewPortStartRow = viewPortStartRow
    data.rowHeight = rowHeight
    data.rowCount = rowCount
    data.viewPortRowCount = viewPortRowCount
    data.imageWidth = imageSize
    data.imageHeight = imageSize
    data.viewPortItems = items

    @setState data

  handleClick: (item) ->
    item.set 'isSelected', !item.get('isSelected')

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
            {@state.viewPortItems.map((item) =>
              <Item imageWidth=@state.imageWidth onClick={@handleClick.bind(@, item)} imageHeight=@state.imageHeight key={item.get('id') || Math.random()} item={item}/>)
            }
          </div>
        </div>
      </div>
    </div>
