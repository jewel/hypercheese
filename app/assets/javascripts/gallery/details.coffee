component 'Details', ({itemId}) ->
  [playing, setPlaying] = React.useState false
  [showControls, setShowControls] = React.useState true
  [slideShow, setSlideShow] = React.useState false
  [zoom, setZoom] = React.useState false
  [infoVisible, setInfoVisible] = React.useState false

  videoRef = React.useRef()
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
        else
          setShowControls false
          stopVideo()
          Store.navigateWithoutHistory linkTo(1)

      when 'ArrowRight', 'KeyJ', 'KeyL'
        setShowControls false
        stopVideo()
        Store.navigateWithoutHistory linkTo(1)
      when 'ArrowLeft', 'KeyH', 'KeyK'
        setShowControls false
        stopVideo()
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

  useEffect ->
    window.addEventListener 'keydown', onKeyDown
    Store.state.openStack.push 'item'

    ->
      window.removeEventListener 'keydown', onKeyDown
  , [itemId, videoRef, setShowControls, stopVideo, linkTo, setSlideShow, setZoom]

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
    Store.navigateWithoutHistory linkTo(dir)

  onClose = (e) ->
    e.stopPropagation()
    Store.navigateBack()

  toggleControls = (e) ->
    # Note: this preventDefault() causes the controls to be inoperable in FF
    e.preventDefault()
    setShowControls !showControls

  onPlay = ->
    videoRef.current?.play()
    setShowControls false

  onPause = ->
    videoRef.current?.pause()

  navigateNext = (e) ->
    e.preventDefault() if e
    stopVideo()
    Store.navigateWithoutHistory linkTo(1)

  navigatePrev = (e) ->
    e.preventDefault() if e
    stopVideo()
    Store.navigateWithoutHistory linkTo(-1)

  stopVideo = ->
    if videoRef.current
      videoRef.current.pause()
      setPlaying(false)

  startVideo = ->
    if videoRef.current
      videoRef.current.play()
      setPlaying(true)

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
          else
            <img
              style={imageStyle}
              onClick={toggleControls}
              src={largeURL(itemId)}
            />
        }
      </Swiper>

      {
        if item && item.variety == 'video'
          if playing
            <ControlIcon title="Pause video" className="video-control" onClick={onPause} icon="fa-pause"/>
          else
            <ControlIcon title="Play video" className="video-control" onClick={onPlay} icon="fa-play"/>
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
              icon="fa-bullhorn"
            />
            <ControlIcon
              className="star"
              title="Bookmark for future reference"
              onClick={onStar}
              icon={if item && item.starred then "fa-star" else "fa-star-o"}
            />
          </Writer>
          {
            # FIXME Only show this on devices without a keyboard
            if fullScreenFunction()
              <ControlIcon
                onClick={onFullScreen}
                icon="fa-arrows-alt"
              />
          }

          <ControlIcon
            onClick={onSelect}
            icon={
              if Store.state.selection[itemId]
                "fa-check-square-o"
              else
                "fa-square-o"
            }
          />
          <ControlIcon
            onClick={onClose}
            icon="fa-close"
          />
        </div>
      </div>
      {
        if judgeMode
          <div className="controls bottom">
            <div></div>
            <div className="centered">
              <RateButton onNext={navigateNext} type="down" itemId={itemId} icon="fa-thumbs-o-down"/>
              <RateButton onNext={navigateNext} type="meh" itemId={itemId} icon="fa-meh-o"/>
              <RateButton onNext={navigateNext} type="up" itemId={itemId} icon="fa-thumbs-o-up"/>
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
