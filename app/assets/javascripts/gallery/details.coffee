@Details = createReactClass
  getInitialState: ->
    Store.state.showInfo = false
    playing: false
    showVideoControls: false
    showControls: true
    slideShow: false

  componentDidMount: ->
    window.addEventListener 'keyup', @onKeyUp
    Store.state.openStack.push 'item'

  componentWillUnmount: ->
    window.removeEventListener 'keyup', @onKeyUp

  onKeyUp: (e) ->
    if e.target.tagName == "INPUT" || e.target.tagName == "TEXTAREA"
      return

    switch e.code
      when 'Space'
        item = Store.fetchItem @props.itemId
        if @refs.video
          if @refs.video.currentTime() > 0
            @hideControls()
            @stopVideo()
            Store.navigateWithoutHistory @linkTo(1)
          else
            @startVideo()
        else
          @hideControls()
          @stopVideo()
          Store.navigateWithoutHistory @linkTo(1)

      when 'ArrowRight', 'KeyJ', 'KeyL'
        @hideControls()
        @stopVideo()
        Store.navigateWithoutHistory @linkTo(1)
      when 'ArrowLeft', 'KeyH', 'KeyK'
        @hideControls()
        @stopVideo()
        Store.navigateWithoutHistory @linkTo(-1)
      when 'KeyF'
        @hideControls()
        @onFullScreen()
      when 'KeyI'
        @onInfo()
      when 'KeyT'
        Store.selectItem @props.itemId
        Store.needsRedraw()
      when 'KeyS'
        @onSlideShow()

  onInfo: (e) ->
    Store.state.showInfo = !Store.state.showInfo
    Store.needsRedraw()

  onStar: (e) ->
    Store.toggleItemStar @props.itemId

  onBullhorn: (e) ->
    Store.toggleItemBullhorn @props.itemId

  onSlideShow: (e) ->
    newState = !@state.slideShow
    @setState
      slideShow: newState
    if newState
      @slideshowTimer = setInterval @advanceSlideshow, 10000
    else
      clearInterval @slideshowTimer

  advanceSlideshow: ->
    @navigateNext()

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

  onSelect: (e) ->
    Store.toggleSelection @props.itemId

  moveTo: (dir) ->
    @stopVideo()

    Store.navigateWithoutHistory @linkTo(dir)

  onClose: (e) ->
    e.stopPropagation()

    Store.navigateBack()

  toggleControls: (e) ->
    # Note: this preventDefault() causes the controls to be inoperable in FF
    e.preventDefault()
    @setState
      showControls: !@state.showControls

  onPlay: (e) ->
    @refs.video.play()
    @hideControls()

  onPause: (e) ->
    @refs.video.pause()

  navigateNext: (e) ->
    e.preventDefault() if e
    @stopVideo()
    Store.navigateWithoutHistory @linkTo(1)

  navigatePrev: (e) ->
    e.preventDefault() if e
    @stopVideo()
    Store.navigateWithoutHistory @linkTo(-1)

  stopVideo: ->
    if @refs.video
      @refs.video.pause()
      @setState
        playing: false

  startVideo: ->
    if @refs.video
      @refs.video.play()
      @setState
        playing: true

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

    return Store.resizedURL size, item

  linkTo: (dir) ->
    itemId = @neighbor(dir)
    if itemId
      return '/items/' + itemId

  showControls: ->
    @setState
      showControls: true

  hideControls: ->
    @setState
      showControls: false

  setPlaying: (val)->
    @setState
      playing: val

  siteIcon: ->
    return @_siteIcon if @_siteIcon?
    elem = document.querySelector 'link[rel=icon]'

    @_siteIcon = elem.href

  render: ->
    Store.state.highlight = @props.itemId
    item = Store.fetchItem @props.itemId

    # make sure that the next batch is loaded if they are a fast clicker
    margin = 10

    if item
      Store.executeSearch item.index - margin, item.index + margin

    prevLink = @linkTo -1
    nextLink = @linkTo 1

    judgeMode = false
    if Store.state.query
      q = new SearchQuery
      q.parse Store.state.query
      judgeMode = true if q.options.unjudged

    # preload neighbors details
    if item && Store.state.showInfo
      Store.getDetails @neighbor(1)
      Store.getDetails @neighbor(-1)

    classes = ['details-window']
    classes.push 'show-controls' if @state.showControls
    classes.push 'judge-bar' if judgeMode

    <div className="details-wrapper">
      <div className={classes.join ' '}>
        <Swiper
          curKey={@props.itemId}
          prevKey={@neighbor(-1)}
          nextKey={@neighbor(1)}
          prevSrc={@largeURL(@neighbor(-1))}
          nextSrc={@largeURL(@neighbor(1))}
          moveTo={@moveTo}
        >
          {
            if item && item.variety == 'video'
              <Video
                ref="video"
                setPlaying={@setPlaying}
                toggleControls={@toggleControls}
                showControls={@showControls}
                poster={@largeURL(@props.itemId)}
                itemId={@props.itemId}
                itemCode={item.code}
              />

            else
              <img ref="curImage" onClick={@toggleControls} src={@largeURL(@props.itemId)} />
          }
        </Swiper>

        {
          if item && item.variety == 'video'
            if @state.playing
              <ControlIcon title="Pause video" className="video-control" onClick={@onPause} icon="fa-pause"/>
            else
              <ControlIcon title="Play video" className="video-control" onClick={@onPlay} icon="fa-play"/>
        }
        <ControlIcon condition=prevLink className="prev-control" href={prevLink} onClick={@navigatePrev} icon="fa-arrow-left" />
        <ControlIcon condition=nextLink className="control next-control" href={nextLink} onClick={@navigateNext} icon="fa-arrow-right" />
        <div className="controls top">
          <Link className="control home" href="/">
            <img src={@siteIcon()}/>
          </Link>

          <div></div>

          <div className="right-side">
            {
              if item
                item.tag_ids.map (tag_id) ->
                  tag = Store.state.tagsById[tag_id]
                  if tag
                    <TagLink key={tag.id} className="tag-link" tag=tag />
            }
            <ControlIcon
              className={ "bullhorn" + if item && item.bullhorned then " active" else "" }
              title="Tells others about this item"
              onClick={@onBullhorn}
              icon="fa-bullhorn"
            />
            <ControlIcon
              className="star"
              title="Bookmark for future reference"
              onClick={@onStar}
              icon={if item && item.starred then "fa-star" else "fa-star-o"}
            />
            {
              # FIXME Only show this on devices without a keyboard
              if @fullScreenFunction()
                <a className="control" href="javascript:void(0)" onClick={@onFullScreen}><i className="fa fa-arrows-alt fa-fw"/></a>
            }
            <ControlIcon
              className={"slideshow" + if @state.slideShow then " active" else ""}
              title="Slideshow"
              onClick={@onSlideShow}
              icon="fa-fighter-jet"
            />

            <a className="control" href="javascript:void(0)" onClick={@onSelect}>
              {
                if Store.state.selection[@props.itemId]
                  <i className="fa fa-check-square-o fa-fw"/>
                else
                  <i className="fa fa-square-o fa-fw"/>
              }
            </a>
            <a className="control" href="javascript:void(0)" onClick={@onInfo}><i className="fa fa-info-circle fa-fw"/></a>
            <a className="control" href="javascript:void(0)" onClick={@onClose}><i className="fa fa-close fa-fw"/></a>
          </div>
        </div>
        {
          if judgeMode
            <div className="controls bottom">
              <div></div>
              <div className="centered">
                <RateButton onNext={@navigateNext} type="down" itemId={@props.itemId} icon="fa-thumbs-o-down"/>
                <RateButton onNext={@navigateNext} type="meh" itemId={@props.itemId} icon="fa-meh-o"/>
                <RateButton onNext={@navigateNext} type="up" itemId={@props.itemId} icon="fa-thumbs-o-up"/>
              </div>
              <div></div>
            </div>
        }
      </div>
      {
        if item && Store.state.showInfo
          <Info item={item} onInfo={@onInfo}/>
      }
    </div>
