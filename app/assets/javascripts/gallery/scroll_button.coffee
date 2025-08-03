component 'ScrollButton', ({height, top, visible}) ->
  [position, setPosition] = useState null
  startY = useRef null
  startPosition = useRef null

  onMouseDown = (e) ->
    return unless e.button == 0
    start e, e.clientY

  onTouchStart = (e) ->
    return unless e.touches.length == 1
    start e, e.touches[0].clientY

  start = (e, y) ->
    e.preventDefault()
    e.stopPropagation()
    startY.current = y
    startPosition.current = initialPosition()

  onMouseMove = (e) ->
    move e, e.clientY

  onTouchMove = (e) ->
    return unless e.touches.length == 1
    move e, e.touches[0].clientY

  move = (e, y) ->
    return unless startY.current?
    e.preventDefault()
    e.stopPropagation()
    diff = y - startY.current

    setPosition startPosition.current + diff
    scrollWindow()

  onMouseUp = (e) ->
    up e

  onTouchEnd = (e) ->
    up e

  up = (e) ->
    return unless startY.current?
    e.preventDefault()
    e.stopPropagation()
    startY.current = null
    startPosition.current = null
    scrollWindow()
    setPosition null

  # Height of widget in pixels
  widgetHeight = 40

  scrollWindow = ->
    windowHeight = document.documentElement.clientHeight
    targetTop = position / (windowHeight - widgetHeight) * (height - windowHeight)
    window.scroll 0, targetTop

  initialPosition = ->
    windowHeight = document.documentElement.clientHeight
    top / (height - windowHeight) * (windowHeight - widgetHeight)

  useEffect ->
    window.addEventListener 'mousemove', onMouseMove, false
    window.addEventListener 'mouseup', onMouseUp, false

    ->
      window.removeEventListener 'mousemove', onMouseMove, false
      window.removeEventListener 'mouseup', onMouseUp, false
  , []

  style =
    position: 'fixed'
    right: '0px'
    top: "#{initialPosition()}px"

  if position != null
    style.top = "#{position}px"

  classes = ["scroll-button", "btn", "btn-default", "btn-primary"]
  classes.push "visible" if visible || (position != null)

  <div style={style} onTouchStart={onTouchStart} onTouchEnd={onTouchEnd} onTouchMove={onTouchMove} onMouseDown={onMouseDown} onMouseMove={onMouseMove} onMouseUp={onMouseUp} className={classes.join ' '}>
    <i className="fa fa-arrows-v"/>
  </div>
