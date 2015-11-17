@ScrollButton = React.createClass
  getInitialState: ->
    position: null

  onMouseDown: (e) ->
    return unless e.button == 0
    @start e, e.clientY

  onTouchStart: (e) ->
    return unless e.touches.length == 1
    @start e, e.touches[0].clientY

  start: (e, y) ->
    e.preventDefault()
    e.stopPropagation()
    @startY = y
    @startPosition = @initialPosition()

  onMouseMove: (e) ->
    @move e, e.clientY

  onTouchMove: (e) ->
    return unless e.touches.length == 1
    @move e, e.touches[0].clientY

  move: (e, y) ->
    return unless @startY?
    e.preventDefault()
    e.stopPropagation()
    diff = y - @startY

    @setState
      position: @startPosition + diff
    @scrollWindow()

  onMouseUp: (e) ->
    @up e

  onTouchEnd: (e) ->
    @up e

  up: (e) ->
    return unless @startY?
    e.preventDefault()
    e.stopPropagation()
    @startY = null
    @startPosition = null
    @scrollWindow()
    @setState
      position: null

  scrollWindow: ->
    targetTop = @state.position / (document.documentElement.clientHeight - @height) * @props.height
    window.scroll 0, targetTop

  componentDidMount: ->
    window.addEventListener 'mousemove', @onMouseMove, false
    window.addEventListener 'mouseup', @onMouseUp, false

  componentWillUnmount: ->
    window.removeEventListener 'mousemove', @onMouseMove, false
    window.removeEventListener 'mouseup', @onMouseUp, false

  # Height of widget in pixels
  height: 40

  initialPosition: ->
    @props.top / @props.height * (document.documentElement.clientHeight - @height)

  render: ->
    style =
      position: 'fixed'
      right: '0px'
      top: "#{@initialPosition()}px"

    if @state.position != null
      style.top = "#{@state.position}px"

    classes = ["scroll-button", "btn", "btn-default", "btn-primary"]
    classes.push "visible" if @props.visible || (@state.position != null)

    <div style=style onTouchStart={@onTouchStart} onTouchEnd={@onTouchEnd} onTouchMove={@onTouchMove} onMouseDown={@onMouseDown} onMouseMove={@onMouseMove} onMouseUp={@onMouseUp} className={classes.join ' '}>
      <i className="fa fa-arrows-v"/>
    </div>
