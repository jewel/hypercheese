@Details = React.createClass
  getInitialState: ->
    playing: false
    showVideoControls: false
    showControls: true

  componentDidMount: ->
    window.addEventListener 'keyup', @onKeyUp

  componentWillUnmount: ->
    window.removeEventListener 'keyup', @onKeyUp

  onKeyUp: (e) ->
    unless e.target == document.body
      return

    switch e.code
      when 'Space', 'ArrowRight', 'KeyJ', 'KeyL'
        @stopVideo()
        Store.navigateToItem @neighbor(1)
      when 'ArrowLeft', 'KeyH', 'KeyK'
        @stopVideo()
        Store.navigateToItem @neighbor(-1)
      when 'KeyF'
        @onFullScreen()
      when 'KeyI'
        @onInfo()

  fullscreenFunctions: [
      'requestFullscreen'
      'mozRequestFullScreen'
      'webkitRequestFullscreen'
      'msRequestFullscreen'
    ]

  fullScreenFunction: ->
    html = document.documentElement
    for i in @fullscreenFunctions
      if html[i]?
        return i
    null


  onFullScreen: (e) ->
    html = document.documentElement
    if func = @fullScreenFunction()
      html[func].apply html

  onTouchStart: (e) ->
    return unless e.touches.length == 1
    touch = e.touches[0]
    @startTouch = touch
    @prevTime = performance.now()
    null

  onTouchMove: (e) ->
    return unless start = @startTouch
    touch = e.touches[0]
    @position = touch.pageX - start.pageX
    @time = performance.now()
    @showSwipe @position

  onTouchEnd: (e) ->
    return unless start = @startTouch
    elapsed = @time - @prevTime
    speed = @position / elapsed
    if Math.abs(speed) > 0.25
      @target = Math.sign(speed)
    else
      @target = 0
    @prevTime = @time
    window.requestAnimationFrame @animateSwipe

  animateSwipe: (now) ->
    elapsed = now - @prevTime
    @prevTime = now
    speed = 4.0
    speed *= -1 if @target < 0
    speed *= -Math.sign(@position) if @target == 0
    oldPosition = @position
    @position += speed * elapsed

    width = document.documentElement.clientWidth

    if @target == 0 && Math.sign(@position) != Math.sign(oldPosition)
      @resetSwipe()
      @showSwipe 0
    else if @target == 1 && @position > width * 1.02
      @showSwipe width * 1.02
      window.requestAnimationFrame =>
        @moveTo -1
    else if @target == -1 && @position < -width * 1.02
      @showSwipe -width * 1.02
      window.requestAnimationFrame =>
        @moveTo 1
    else
      @showSwipe @position
      window.requestAnimationFrame @animateSwipe

  resetSwipe: ->
    @position = null
    @prevTime = null
    @startTouch = null

  showSwipe: (position) ->
    style = "translate3d(#{position}px, 0px, 0px)"
    @refs.prev.style.transform = style if @refs.prev
    @refs.cur.style.transform = style if @refs.cur
    @refs.next.style.transform = style if @refs.next

  moveTo: (dir) ->
    @stopVideo()

    @resetSwipe()

    Store.navigateToItem @neighbor(dir)
    @showSwipe 0

  onClose: (e) ->
    e.stopPropagation()

    Store.state.showItem = null
    Store.needsRedraw()

  toggleControls: (e) ->
    # Note: this preventDefault() causes the controls to be inoperable in FF
    e.preventDefault()
    @setState
      showControls: !@state.showControls

  onPlay: (e) ->
    @refs.video.play()
    @setState
      playing: true
      playStarted: true
      showControls: @state.playStarted

  onPause: (e) ->
    @refs.video.pause()
    @setState
      showVideoControls: false

  onVideoPlaying: (e) ->
    @setState
      playing: true

  onVideoPause: (e) ->
    @setState
      playing: false

  onVideoEnded: (e) ->
    @setState
      showVideoControls: false
      showControls: true

  navigateNext: (e) ->
    e.preventDefault() if e
    @stopVideo()
    Store.navigateToItem @neighbor(1)

  navigatePrev: (e) ->
    e.preventDefault() if e
    @stopVideo()
    Store.navigateToItem @neighbor(-1)

  stopVideo: ->
    @refs.video.pause()
    @setState
      playing: false
      showVideoControls: false

  neighbor: (dir) ->
    item = Store.getItem @props.itemId
    return unless item

    newIndex = item.index + dir
    Store.state.items[newIndex]

  largeURL: (itemId) ->
    return unless itemId

    item = Store.getItem itemId
    if !item
      return null

    size = if item.variety == 'video'
      'exploded'
    else
      'large'

    return "/data/resized/#{size}/#{itemId}.jpg"

  siteIcon: ->
    return @_siteIcon if @_siteIcon?
    elem = document.querySelector 'link[rel=icon]'

    @_siteIcon = elem.href

  render: ->
    item = Store.fetchItem @props.itemId

    # make sure that the next batch is loaded if they are a fast clicker
    margin = 10

    if item
      Store.executeSearch item.index - margin, item.index + margin

    classes = ['details-window']
    classes.push 'show-controls' if @state.showControls

    <div className="details-wrapper">
      <div className={classes.join ' '} onTouchStart={@onTouchStart} onTouchMove={@onTouchMove} onTouchEnd={@onTouchEnd} onMouseMove={@onMouseMove}>
        <div key={@props.itemId} ref="cur" className="detailed-image">
          {
            if item && item.variety == 'video'
              <video src={"/data/resized/stream/#{@props.itemId}.mp4"} ref="video" onClick={@toggleControls} controls={@state.showVideoControls}} preload="none" poster={@largeURL(@props.itemId)} onPause={@onVideoPause} onPlaying={@onVideoPlaying} onEnded={@onVideoEnded}/>

            else
              <img ref="curImage" onClick={@toggleControls} src={@largeURL(@props.itemId)} />
          }
        </div>
        <div key={@neighbor(-1)} ref="prev" className="detailed-prev">
          <img ref="prevImage" src={@largeURL(@neighbor(-1))}/>
        </div>
        <div key={@neighbor(1)} ref="next" className="detailed-next">
          <img ref="nextImage" src={@largeURL(@neighbor( 1))}/>
        </div>

        {
          if item && item.variety == 'video'
            if @state.playing
              <a title="Pause video" className="control video-control" href="javascript:void(0)" onClick={@onPause}><i className="fa fa-fw fa-pause"></i></a>
            else
              <a title="Play video" className="control video-control" href="javascript:void(0)" onClick={@onPlay}><i className="fa fa-fw fa-play"></i></a>
        }
        {
          if @neighbor(-1)
            <a className="control prev-control" href="javascript:void(0)" onClick={@navigatePrev}><i className="fa fa-arrow-left"/></a>
        }
        {
          if @neighbor(1)
            <a className="control next-control" href="javascript:void(0)" onClick={@navigateNext}><i className="fa fa-arrow-right"/></a>
        }
        <div className="controls top">
          <div></div>

          <div className="right-side">
            <a className="control" href="/shares/#{Store.state.shareCode}/download_item/#{@props.itemId}"><i className="fa fa-download fa-fw" /></a>
            {
              # FIXME Only show this on devices without a keyboard
              if @fullScreenFunction()
                <a className="control" href="javascript:void(0)" onClick={@onFullScreen}><i className="fa fa-arrows-alt fa-fw"/></a>
            }
            <a className="control" href="javascript:void(0)" onClick={@onClose}><i className="fa fa-close fa-fw"/></a>
          </div>
        </div>
      </div>
    </div>
