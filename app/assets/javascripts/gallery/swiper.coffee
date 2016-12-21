@Swiper = React.createClass
  onTouchStart: (e) ->
    return unless e.touches.length == 1
    touch = e.touches[0]
    @startTouch = touch
    @prevTime = performance.now()
    null

  onTouchMove: (e) ->
    unless e.touches.length == 1
      @startTouch = null
      return
    return unless start = @startTouch
    touch = e.touches[0]
    @position = touch.pageX - start.pageX
    @time = performance.now()
    @show @position

  onTouchEnd: (e) ->
    return unless start = @startTouch
    elapsed = @time - @prevTime
    speed = @position / elapsed
    if Math.abs(speed) > 0.25
      @target = Math.sign(speed)
    else
      @target = 0
    @prevTime = @time
    window.requestAnimationFrame @animate

  animate: (now) ->
    elapsed = now - @prevTime
    @prevTime = now
    speed = 4.0
    speed *= -1 if @target < 0
    speed *= -Math.sign(@position) if @target == 0
    oldPosition = @position
    @position += speed * elapsed

    width = document.documentElement.clientWidth

    if @target == 0 && Math.sign(@position) != Math.sign(oldPosition)
      @reset()
      @show 0
    else if @target == 1 && @position > width * 1.02
      @show width * 1.02
      window.requestAnimationFrame =>
        @moveTo -1
    else if @target == -1 && @position < -width * 1.02
      @show -width * 1.02
      window.requestAnimationFrame =>
        @moveTo 1
    else
      @show @position
      window.requestAnimationFrame @animate

  reset: ->
    @position = null
    @prevTime = null
    @startTouch = null

  show: (position) ->
    style = "translate3d(#{position}px, 0px, 0px)"
    @refs.prev.style.transform = style if @refs.prev
    @refs.cur.style.transform = style if @refs.cur
    @refs.next.style.transform = style if @refs.next

  moveTo: (dir) ->
    @props.moveTo(dir)
    @reset()
    @show 0

  render: ->
    <div onTouchStart={@onTouchStart} onTouchMove={@onTouchMove} onTouchEnd={@onTouchEnd} onMouseMove={@onMouseMove}>
      <div key={@props.curKey} ref="cur" className="detailed-image">
       {@props.children}
      </div>
       
      <div key={@props.prevKey} ref="prev" className="detailed-prev">
        <img ref="prevImage" src={@props.prevSrc}/>
      </div>
      <div key={@props.nextKey} ref="next" className="detailed-next">
        <img ref="nextImage" src={@props.nextSrc}/>
      </div>
    </div>
