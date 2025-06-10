component 'Swiper', ({children, curKey, prevKey, nextKey, prevSrc, nextSrc, moveTo}) ->
  [position, setPosition] = useState null
  [prevTime, setPrevTime] = useState null
  [startTouch, setStartTouch] = useState null
  [target, setTarget] = useState null

  useEffect ->
    if target?
      window.requestAnimationFrame animate
    ->
  , [target]

  onTouchStart = (e) ->
    return unless e.touches.length == 1
    touch = e.touches[0]
    setStartTouch touch
    setPrevTime performance.now()
    null

  onTouchMove = (e) ->
    unless e.touches.length == 1
      setStartTouch null
      return
    return unless start = startTouch
    touch = e.touches[0]
    newPosition = touch.pageX - start.pageX
    setPosition newPosition
    setPrevTime performance.now()

  onTouchEnd = (e) ->
    return unless start = startTouch
    elapsed = performance.now() - prevTime
    speed = position / elapsed
    if Math.abs(speed) > 0.25
      setTarget Math.sign(speed)
    else
      setTarget 0
    setPrevTime performance.now()

  animate = (now) ->
    elapsed = now - prevTime
    setPrevTime now
    speed = 4.0
    speed *= -1 if target < 0
    speed *= -Math.sign(position) if target == 0
    oldPosition = position
    newPosition = position + speed * elapsed

    width = document.documentElement.clientWidth

    if target == 0 && Math.sign(newPosition) != Math.sign(oldPosition)
      reset()
    else if target == 1 && newPosition > width * 1.02
      setPosition width * 1.02
      window.requestAnimationFrame ->
        handleMoveTo -1
    else if target == -1 && newPosition < -width * 1.02
      setPosition -width * 1.02
      window.requestAnimationFrame ->
        handleMoveTo 1
    else
      setPosition newPosition
      window.requestAnimationFrame animate

  reset = ->
    setPosition null
    setPrevTime null
    setStartTouch null
    setTarget null

  handleMoveTo = (target) ->
    moveTo target
    reset()

  transformStyle = "translate3d(#{position ? 0}px, 0px, 0px)"

  <div onTouchStart={onTouchStart} onTouchMove={onTouchMove} onTouchEnd={onTouchEnd}>
    <div key={curKey} className="detailed-image" style={transform: transformStyle}>
      {children}
    </div>

    <div key={prevKey} className="detailed-prev" style={transform: transformStyle}>
      <img src={prevSrc}/>
    </div>
    <div key={nextKey} className="detailed-next" style={transform: transformStyle}>
      <img src={nextSrc}/>
    </div>
  </div>
