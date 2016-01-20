@Details = React.createClass
  getInitialState: ->
    playing: false
    showInfo: false
    showControls: true

  onInfo: (e) ->
    @setState
      showInfo: !@state.showInfo

  onStar: (e) ->
    Store.toggleItemStar @props.itemId

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

  onTouchStart: (e) ->
    return unless e.touches.length == 1
    touch = e.touches[0]
    @startTouch = touch
    @prevTime = performance.now()
    @position = 0
    @speed = 0
    null

  onTouchMove: (e) ->
    return unless start = @startTouch
    touch = e.touches[0]
    position = touch.pageX - start.pageX
    @showSwipe position
    now = performance.now()
    elapsed = now - @prevTime
    @prevTime = now
    @speed = (position - @position) / elapsed
    @position = position

  onTouchEnd: (e) ->
    return unless @position?
    window.requestAnimationFrame(@animateSwipe)

  animateSwipe: (now) ->
    elapsed = now - @prevTime
    @prevTime = now
    oldPosition = @position
    @position += @speed * elapsed
    width = document.documentElement.clientWidth

    # accelerate in current direction
    acc = 0.1 * Math.sign(@position)

    distanceFromStart = Math.abs(@position/width)

    # if close to center, spring back
    if distanceFromStart < 0.3
      acc = 0.05 * -Math.sign(@position)

    @speed += acc

    if Math.sign(@position) != Math.sign(oldPosition)
      # Crossed center position
      @resetSwipe()
      @showSwipe 0
    else if @position > width * 1.02
      @moveTo -1, @refs.prevImage
    else if @position < -(width * 1.02)
      @moveTo 1, @refs.nextImage
    else
      @showSwipe @position
      window.requestAnimationFrame @animateSwipe

  resetSwipe: ->
    @position = null
    @speed = null
    @prevTime = null
    @startTouch = null

  showSwipe: (amount) ->
    style = "translate3d(#{amount}px, 0px, 0px)"
    @refs.prev.style.transform = style if @refs.prev
    @refs.cur.style.transform = style if @refs.cur
    @refs.next.style.transform = style if @refs.next

  moveTo: (dir, image) ->
    @stopVideo()

    @resetSwipe()
    # Avoid temporary glitch while swipe is reset by updating the image early
    # FIXME Nothing is happening for videos
    if @refs.curImage
      @refs.curImage.src = image.src
    else if @refs.video
      @refs.video.poster = image.src

    window.location.hash = @linkTo dir
    @showSwipe 0

  onClose: (e) ->
    e.stopPropagation()

    window.location.hash = '/search/' + encodeURI(@props.search)

  toggleControls: (e) ->
    @setState
      showControls: !@state.showControls

  onPlay: (e) ->
    @refs.video.play()
    @setState
      playing: true

  stopVideo: ->
    @setState
      playing: false

  neighbor: (dir) ->
    item = Store.getItem @props.itemId
    return unless item

    newIndex = item.index + dir
    Store.state.items[newIndex]

  suppress: (e) ->
    e.stopPropagation()

  neighborId: (dir) ->
    item = @neighbor dir
    if item
      item
    else
      # Better to be wrong than to return null, since this is going to be used
      # for "key"
      @props.itemId + dir

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
    if item && @state.showInfo
      Store.getDetails @neighbor(1)
      Store.getDetails @neighbor(-1)

    classes = ['details-window']
    classes.push 'show-controls' if @state.showControls

    <div className="details-wrapper">
      <div className={classes.join ' '} onTouchStart={@onTouchStart} onTouchMove={@onTouchMove} onTouchEnd={@onTouchEnd} onDoubleClick={@onClose}>
        <div ref="cur" className="detailed-image">
          {
            if item && item.variety == 'video'
              <video src={"/data/resized/stream/#{@props.itemId}.mp4"} ref="video" onClick={@toggleControls} controls={@state.playing}} preload="none" poster={@largeURL(@props.itemId)}/>

            else
              <img ref="curImage" onClick={@toggleControls} src={@largeURL(@props.itemId)} />
          }
        </div>
        <div ref="prev" className="detailed-prev">
          <img ref="prevImage" src={@largeURL(@neighbor(-1))}/>
        </div>
        <div ref="next" className="detailed-next">
          <img ref="nextImage" src={@largeURL(@neighbor( 1))}/>
        </div>

        {
          if item && item.variety == 'video' && !@state.playing
            <a title="Play video" className="control play-control" href="javascript:void(0)" onClick={@onPlay}>&#9654;</a>
        }
        {
          if prevLink
            <a className="control prev-control" href="##{prevLink}" onClick={@stopVideo} onDoubleClick={@suppress}><i className="fa fa-arrow-left"/></a>
        }
        {
          if nextLink
            <a className="control next-control" href="##{nextLink}" onClick={@stopVideo} onDoubleClick={@suppress}><i className="fa fa-arrow-right"/></a>
        }
        <div className="controls">
          {
            if item
              item.tag_ids.map (tag_id) ->
                tag = Store.state.tagsById[tag_id]
                if tag
                  <a key={tag.id} href={"#/tags/#{tag.id}/#{tag.label}"}>
                    <Tag tag=tag />
                  </a>
          }
          <a className="control star" href="javascript:void(0)" onClick={@onStar}>
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
      {
        if item && @state.showInfo
          <Info item={item} onInfo={@onInfo}/>
      }
    </div>
