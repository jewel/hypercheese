@Details = React.createClass
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
    unless e.target == document.body
      return

    switch e.code
      when 'Space', 'ArrowRight', 'KeyJ', 'KeyL'
        @stopVideo()
        Store.navigateWithoutHistory @linkTo(1)
      when 'ArrowLeft', 'KeyH', 'KeyK'
        @stopVideo()
        Store.navigateWithoutHistory @linkTo(-1)
      when 'KeyF'
        @onFullScreen()
      when 'KeyI'
        @onInfo()
      when 'KeyT'
        Store.selectItem @props.itemId
        Store.needsRedraw()

  onInfo: (e) ->
    Store.state.showInfo = !Store.state.showInfo
    Store.needsRedraw()

  onStar: (e) ->
    Store.toggleItemStar @props.itemId

  onBullhorn: (e) ->
    Store.toggleItemBullhorn @props.itemId

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
    @setState
      showControls: false
      showVideoControls: true

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

  linkTo: (dir) ->
    itemId = @neighbor(dir)
    if itemId
      return '/items/' + itemId

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

    # preload neighbors details
    if item && Store.state.showInfo
      Store.getDetails @neighbor(1)
      Store.getDetails @neighbor(-1)

    classes = ['details-window']
    classes.push 'show-controls' if @state.showControls

    <div className="details-wrapper">
      <div className={classes.join ' '}>
        <Swiper  curKey={@props.itemId} prevKey={@neighbor(-1)} nextKey={@neighbor(1)} prevSrc={@largeURL(@neighbor(-1))} nextSrc={@largeURL(@neighbor(1))} moveTo={@moveTo}>
          {
            if item && item.variety == 'video'
              <video src={"/data/resized/stream/#{@props.itemId}.mp4"} ref="video" onClick={@toggleControls} controls={@state.showVideoControls}} preload="none" poster={@largeURL(@props.itemId)} onPause={@onVideoPause} onPlaying={@onVideoPlaying} onEnded={@onVideoEnded} />

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
        {
          if prevLink
            <a className="control prev-control" href={prevLink}" onClick={@navigatePrev}><i className="fa fa-arrow-left"/></a>
        }
        {
          if nextLink
            <a className="control next-control" href={nextLink}" onClick={@navigateNext}><i className="fa fa-arrow-right"/></a>
        }
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
            <a className="control bullhorn" title="Tells others about this item" href="javascript:void(0)" onClick={@onBullhorn}>
              {
                if item
                  if item.bullhorned
                    <i className="fa fa-bullhorn fa-fw active"/>
                  else
                    <i className="fa fa-bullhorn fa-fw"/>
              }
            </a>
            <a className="control star" title="Bookmark for future reference" href="javascript:void(0)" onClick={@onStar}>
              {
                if item
                  if item.starred
                    <i className="fa fa-star fa-fw"/>
                  else
                    <i className="fa fa-star-o fa-fw"/>
              }
            </a>
            {
              # FIXME Only show this on devices without a keyboard
              if @fullScreenFunction()
                <a className="control" href="javascript:void(0)" onClick={@onFullScreen}><i className="fa fa-arrows-alt fa-fw"/></a>
            }
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
        <div className="controls bottom">
          <div></div>
          <div className="centered">
            <RateButton onNext={@navigateNext} type="down" itemId={@props.itemId} icon="fa-thumbs-o-down"/>
            <RateButton onNext={@navigateNext} type="meh" itemId={@props.itemId} icon="fa-meh-o"/>
            <RateButton onNext={@navigateNext} type="up" itemId={@props.itemId} icon="fa-thumbs-o-up"/>
          </div>
          <div></div>
        </div>
      </div>
      {
        if item && Store.state.showInfo
          <Info item={item} onInfo={@onInfo}/>
      }
    </div>
