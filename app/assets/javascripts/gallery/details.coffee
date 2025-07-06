component 'Details', ({itemId}) ->
  [playing, setPlaying] = React.useState false
  [showControls, setShowControls] = React.useState true
  [slideShow, setSlideShow] = React.useState false
  [zoom, setZoom] = React.useState false
  [infoVisible, setInfoVisible] = React.useState false
  [playingMotion, setPlayingMotion] = React.useState false

  videoRef = React.useRef()
  motionVideoRef = React.useRef()
  infoRef = React.useRef()

  fullscreenFunctions = [
    'requestFullscreen'
    'mozRequestFullScreen'
    'webkitRequestFullscreen'
    'msRequestFullscreen'
  ]

  fullScreenFunction = ->
    html = document.documentElement
    for i in fullscreenFunctions
      if html[i]?
        return i
    null

  checkInfoVisibility = ->
    infoElement = infoRef.current
    return unless infoElement
    rect = infoElement.getBoundingClientRect()
    newInfoVisible = Math.round(rect.top) < window.innerHeight
    if newInfoVisible != infoVisible
      setInfoVisible(newInfoVisible)

  onKeyDown = (e) ->
    if e.target.tagName == "INPUT" || e.target.tagName == "TEXTAREA"
      return

    switch e.code
      when 'Space'
        # prevent scrolling the page
        e.preventDefault()
        e.stopPropagation()
        item = Store.fetchItem itemId
        if videoRef.current
          if videoRef.current.currentTime > 0
            setShowControls false
            stopVideo()
            Store.navigateWithoutHistory linkTo(1)
          else
            startVideo()
        else if motionVideoRef.current && playingMotion
          stopMotionVideo()
        else if item.has_motion_video && item.variety == 'photo'
          startMotionVideo()
        else
          setShowControls false
          stopVideo()
          Store.navigateWithoutHistory linkTo(1)

      when 'ArrowRight', 'KeyJ', 'KeyL'
        setShowControls false
        stopVideo()
        stopMotionVideo()
        Store.navigateWithoutHistory linkTo(1)
      when 'ArrowLeft', 'KeyH', 'KeyK'
        setShowControls false
        stopVideo()
        stopMotionVideo()
        Store.navigateWithoutHistory linkTo(-1)
      when 'KeyF'
        setShowControls false
        onFullScreen()
      when 'KeyI'
        infoRef.current?.scrollIntoView behavior: 'smooth'
      when 'KeyT'
        Store.selectItem itemId
        Store.needsRedraw()
      when 'KeyS'
        onSlideShow()
      when 'KeyZ'
        onZoom()
      when 'KeyM'
        # Toggle motion video for photos
        item = Store.fetchItem itemId
        if item.has_motion_video && item.variety == 'photo'
          if playingMotion
            stopMotionVideo()
          else
            startMotionVideo()

  useEffect ->
    window.addEventListener 'keydown', onKeyDown
    Store.state.openStack.push 'item'

    ->
      window.removeEventListener 'keydown', onKeyDown
  , [itemId, videoRef, motionVideoRef, setShowControls, stopVideo, linkTo, setSlideShow, setZoom, playingMotion]

  onStar = (e) ->
    Store.toggleItemStar itemId

  onBullhorn = (e) ->
    Store.toggleItemBullhorn itemId

  onSlideShow = (e) ->
    newState = !slideShow
    setSlideShow(newState)
    if newState
      slideshowTimer = setInterval advanceSlideshow, 10000
    else
      clearInterval slideshowTimer

  advanceSlideshow = ->
    navigateNext()

  onZoom = (e) ->
    setZoom(!zoom)

  onFullScreen = (e) ->
    html = document.documentElement
    if func = fullScreenFunction()
      html[func].apply html

  onSelect = (e) ->
    Store.toggleSelection itemId

  moveTo = (dir) ->
    stopVideo()
    stopMotionVideo()
    Store.navigateWithoutHistory linkTo(dir)

  onClose = (e) ->
    e.stopPropagation()
    Store.navigateBack()

  toggleControls = (e) ->
    # Note: this preventDefault() causes the controls to be inoperable in FF
    e.preventDefault()
    setShowControls !showControls

  onMotionVideoClick = (e) ->
    e.preventDefault()
    item = Store.fetchItem itemId
    if item.has_motion_video && item.variety == 'photo'
      if playingMotion
        stopMotionVideo()
      else
        startMotionVideo()

  onPlay = ->
    videoRef.current?.play()
    setShowControls false

  onPause = ->
    videoRef.current?.pause()

  navigateNext = (e) ->
    e.preventDefault() if e
    stopVideo()
    stopMotionVideo()
    Store.navigateWithoutHistory linkTo(1)

  navigatePrev = (e) ->
    e.preventDefault() if e
    stopVideo()
    stopMotionVideo()
    Store.navigateWithoutHistory linkTo(-1)

  stopVideo = ->
    if videoRef.current
      videoRef.current.pause()
      setPlaying(false)

  startVideo = ->
    if videoRef.current
      videoRef.current.play()
      setPlaying(true)

  startMotionVideo = ->
    if motionVideoRef.current
      motionVideoRef.current.currentTime = 0
      motionVideoRef.current.play()
      setPlayingMotion(true)
      setShowControls false

  stopMotionVideo = ->
    if motionVideoRef.current
      motionVideoRef.current.pause()
      setPlayingMotion(false)
      setShowControls true

  onMotionVideoEnded = ->
    setPlayingMotion(false)
    setShowControls true

  neighbor = (dir) ->
    item = Store.getItem itemId
    return unless item

    newIndex = item.index + dir
    Store.state.items[newIndex]

  largeURL = (itemId) ->
    return unless itemId

    item = Store.getItem itemId
    if !item
      return null

    size = if item.variety == 'video'
      'exploded'
    else
      'large'

    return Store.resizedURL size, item

  linkTo = (dir) ->
    newItemId = neighbor(dir)
    if newItemId
      return '/items/' + newItemId

  siteIcon = ->
    return _siteIcon if _siteIcon?
    elem = document.querySelector 'link[rel=icon]'
    _siteIcon = elem.href

  useEffect ->
    window.addEventListener 'scroll', checkInfoVisibility

    ->
      window.removeEventListener 'scroll', checkInfoVisibility
  , [infoRef, setInfoVisible, infoVisible]

  Store.state.highlight = itemId
  item = Store.fetchItem itemId

  # make sure that the next batch is loaded if they are a fast clicker
  margin = 10

  if item
    Store.executeSearch item.index - margin, item.index + margin

  prevLink = linkTo -1
  nextLink = linkTo 1

  judgeMode = false
  if Store.state.query
    q = new SearchQuery Store.state.query
    judgeMode = true if q.options.unjudged

  classes = ['details-window']
  classes.push 'show-controls' if showControls
  classes.push 'judge-bar' if judgeMode

  imageStyle = {}
  if zoom
    imageStyle.objectFit = 'cover'

  <div className="details-wrapper">
    <div className={classes.join ' '}>
      <Swiper
        curKey={itemId}
        prevKey={neighbor(-1)}
        nextKey={neighbor(1)}
        prevSrc={largeURL(neighbor(-1))}
        nextSrc={largeURL(neighbor(1))}
        moveTo={moveTo}
      >
        {
          if item && item.variety == 'video'
            <Video
              videoRef={videoRef}
              setPlaying={setPlaying}
              toggleControls={toggleControls}
              showControls={-> setShowControls true}
              poster={largeURL(itemId)}
              itemId={itemId}
              itemCode={item.code}
            />
          else if item && playingMotion && item.motion_video_url
            <video
              ref={motionVideoRef}
              src={item.motion_video_url}
              autoPlay
              loop
              playsInline
              onEnded={onMotionVideoEnded}
              onClick={onMotionVideoClick}
              style={imageStyle}
            />
          else
            <div className="photo-container" onClick={onMotionVideoClick}>
              <img
                style={imageStyle}
                src={largeURL(itemId)}
              />
              {
                if item && item.has_motion_video && item.variety == 'photo' && !playingMotion
                  <div className="motion-play-overlay">
                    <i className="fas fa-play-circle" title="Click to play motion video (press M)"></i>
                  </div>
              }
            </div>
        }
      </Swiper>

      {
        if item && item.variety == 'video'
          if playing
            <ControlIcon title="Pause video" className="video-control" onClick={onPause} icon="fa-pause"/>
          else
            <ControlIcon title="Play video" className="video-control" onClick={onPlay} icon="fa-play"/>
      }
      {
        if item && item.has_motion_video && item.variety == 'photo'
          if playingMotion
            <ControlIcon title="Stop motion video" className="motion-control" onClick={stopMotionVideo} icon="fa-stop"/>
          else
            <ControlIcon title="Play motion video" className="motion-control" onClick={startMotionVideo} icon="fa-play"/>
      }
      <ControlIcon condition={prevLink} className="prev-control" href={prevLink} onClick={navigatePrev} icon="fa-arrow-left" />
      <ControlIcon condition={nextLink} className="control next-control" href={nextLink} onClick={navigateNext} icon="fa-arrow-right" />
      <div className="controls top">
        <Link className="control home" href="/">
          <img src={siteIcon()}/>
        </Link>

        <div></div>

        <div className="right-side">
          {
            if item
              item.tag_ids.map (tag_id) ->
                tag = Store.state.tagsById[tag_id]
                if tag
                  <TagLink key={tag.id} className="tag-link" tag={tag}/>
          }
          <PresentButton
            url={largeURL itemId}
            streamUrl={item && item.variety == 'video' && Store.resizedURL('stream', item.id, item.code)}
            video={videoRef.current}
          />
          <Writer>
            <ControlIcon
              className={ "bullhorn" + if item && item.bullhorned then " active" else "" }
              title="Tells others about this item"
              onClick={onBullhorn}
              icon="fas fa-bullhorn"
            />
            <ControlIcon
              className="star"
              title="Bookmark for future reference"
              onClick={onStar}
              icon={if item && item.starred then "fas fa-star" else "far fa-star"}
            />
          </Writer>
          {
            # FIXME Only show this on devices without a keyboard
            if fullScreenFunction()
              <ControlIcon
                onClick={onFullScreen}
                icon="fas fa-expand"
              />
          }

          <ControlIcon
            onClick={onSelect}
            icon={
              if Store.state.selection[itemId]
                "far fa-check-square"
              else
                "far fa-square"
            }
          />
          <ControlIcon
            onClick={onClose}
            icon="fas fa-times"
          />
        </div>
      </div>
      {
        if judgeMode
          <div className="controls bottom">
            <div></div>
            <div className="centered">
              <RateButton onNext={navigateNext} type="down" itemId={itemId} icon="far fa-thumbs-down"/>
              <RateButton onNext={navigateNext} type="meh" itemId={itemId} icon="far fa-meh"/>
              <RateButton onNext={navigateNext} type="up" itemId={itemId} icon="far fa-thumbs-up"/>
            </div>
            <div></div>
          </div>
      }
    </div>
    {
      if item
        <ErrorBoundary>
          <Info containerRef={infoRef} item={item} isVisible={infoVisible}/>
        </ErrorBoundary>
    }
  </div>
