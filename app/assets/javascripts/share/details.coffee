@Details = createReactClass
  getInitialState: ->
    Store.state.showInfo = false
    playing: false
    showVideoControls: false
    showControls: true

  componentDidMount: ->
    window.addEventListener 'keyup', @onKeyUp

  componentWillUnmount: ->
    window.removeEventListener 'keyup', @onKeyUp

  onKeyUp: (e) ->
    if e.target.tagName == "INPUT" || e.target.tagName == "TEXTAREA"
      return

    switch e.code
      when 'Space', 'ArrowRight', 'KeyJ', 'KeyL'
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

  onInfo: (e) ->
    Store.state.showInfo = !Store.state.showInfo
    Store.needsRedraw()

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

  moveTo: (dir) ->
    @stopVideo()

    Store.navigateToItem @neighbor(dir)

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

    Store.resizedURL size, item

  linkTo: (dir) ->
    itemId = @neighbor(dir)
    if itemId
      return "/shares/#{Store.state.shareCode}/#{itemId}"

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
    item = Store.fetchItem @props.itemId

    # make sure that the next batch is loaded if they are a fast clicker
    margin = 10

    if item
      Store.executeSearch item.index - margin, item.index + margin


    prevLink = @linkTo -1
    nextLink = @linkTo 1

    classes = ['details-window']
    classes.push 'show-controls' if @state.showControls

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
              />

            else
              <img ref="curImage" onClick={@toggleControls} src={@largeURL(@props.itemId)} />
          }
        </Swiper>

        {
          if item && item.variety == 'video'
            if @state.playing
              <a title="Pause video" className="control video-control" href="javascript:void(0)" onClick={@onPause}><i className="fa fa-fw fa-pause"></i></a>
            else
              <a title="Play video" className="control video-control" href="javascript:void(0)" onClick={@onPlay}><i className="fa fa-fw fa-play"></i></a>
        }
        <ControlIcon condition=prevLink className="prev-control" href={prevLink} onClick={@navigatePrev} icon="fa-arrow-left" />
        <ControlIcon condition=nextLink className="control next-control" href={nextLink} onClick={@navigateNext} icon="fa-arrow-right" />
        <div className="controls top">
          <div className="details-label">{item && item.filename}</div>
          <div></div>

          <div className="right-side">
            <a className="control" href="/shares/#{Store.state.shareCode}/download_item/#{@props.itemId}"><i className="fa fa-download fa-fw" /></a>
            {
              # FIXME Only show this on devices without a keyboard
              if @fullScreenFunction()
                <a className="control" href="javascript:void(0)" onClick={@onFullScreen}><i className="fa fa-arrows-alt fa-fw"/></a>
            }
            <a className="control" href="javascript:void(0)" onClick={@onInfo}><i className="fa fa-info-circle fa-fw"/></a>
            <a className="control" href="javascript:void(0)" onClick={@onClose}><i className="fa fa-close fa-fw"/></a>
          </div>
        </div>
      </div>
      {
        if item && Store.state.showInfo
          <Info item={item} onInfo={@onInfo}/>
      }
    </div>
