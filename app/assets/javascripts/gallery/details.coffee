@Details = React.createClass
  getInitialState: ->
    playing: false
    showInfo: false

  onInfo: (e) ->
    @setState
      showInfo: !@state.showInfo

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
    null

  onTouchMove: (e) ->
    return unless start = @startTouch
    touch = e.touches[0]
    @showSwipe touch.pageX - start.pageX
    @touchPosition = touch.pageX

  onTouchEnd: (e) ->
    return unless start = @startTouch
    return unless @touchPosition?
    pageWidth = document.documentElement.clientWidth
    # must move at least half the page
    diff = @touchPosition - start.pageX
    @startTouch = null
    @touchPosition = null
    if Math.abs(diff) > pageWidth / 3
      if diff > 0
        @moveTo -1
      else
        @moveTo 1
    @showSwipe 0

  showSwipe: (amount) ->
    style = "translateX(#{amount}px)"
    @refs.prevImage.style.transform = style
    @refs.nextImage.style.transform = style
    (@refs.image || @refs.video).style.transform = style

  moveTo: (dir) ->
    @stopVideo()

    window.location.hash = @linkTo dir

  onClose: (e) ->
    e.stopPropagation()

    window.location.hash = '/search/' + encodeURI(@props.search)

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

    <div className="details-wrapper">
      <div className="details-window" onTouchStart={@onTouchStart} onTouchMove={@onTouchMove} onTouchEnd={@onTouchEnd}>
        <img className="detailed-prev" ref="prevImage" src={@largeURL(@neighbor(-1))}/>
        <img className="detailed-next" ref="nextImage" src={@largeURL(@neighbor( 1))}/>
        {
          if item && item.variety == 'video'
            <video className="detailed-image" src={"/data/resized/stream/#{@props.itemId}.mp4"} ref="video" controls={@state.playing}} preload="none" poster={@largeURL(@props.itemId)}/>

          else
            <img ref="image" onClick={@onClose} className="detailed-image" src={@largeURL(@props.itemId)} />
        }

        {
          if item && item.variety == 'video' && !@state.playing
            <a title="Play video" className="control play-control" href="javascript:void(0)" onClick={@onPlay}>&#9654;</a>
        }
        {
          if prevLink
            <a className="control prev-control" href="##{prevLink}" onClick={@stopVideo}><i className="fa fa-arrow-left"/></a>
        }
        {
          if nextLink
            <a className="control next-control" href="##{nextLink}" onClick={@stopVideo}><i className="fa fa-arrow-right"/></a>
        }
        <div className="controls">
          {
            if item
              item.tag_ids.map (tag_id) ->
                tag = Store.state.tagsById[tag_id]
                if tag
                  tagIconURL = "/data/resized/square/#{tag.icon}.jpg"
                  <img title={tag.label} className="tag-icon" key={tag_id} src={tagIconURL}/>
          }
          <a className="control" href="javascript:void(0)" onClick={@onStar}>
            {
              if @props.itemId % 2 == 0
                <i className="fa fa-star-o fa-fw"/>
              else
                <i className="fa fa-star fa-fw"/>
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
          <Info item={item}/>
      }
    </div>
