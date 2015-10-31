@Details = React.createClass
  getInitialState: ->
    newComment: ''
    playing: false

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
    pageWidth = document.documentElement.clientWidth
    # must move at least half the page
    diff = @touchPosition - start.pageX
    @startTouch = null
    @touchPosition = 0
    if Math.abs(diff) > pageWidth / 3
      if diff > 0
        @moveTo 1
      else
        @moveTo -1
    @showSwipe 0

  showSwipe: (amount) ->
    (@refs.image || @refs.video).style.transform = "translateX(#{amount}px)"

  moveTo: (dir) ->
    @stopVideo()

    window.location.hash = @linkTo dir

  onClose: (e) ->
    e.stopPropagation()
    @props.updateHighlight @props.itemId

    if @props.search == ''
      window.location.hash = '/'
    else
      window.location.hash = '/search/' + encodeURI(@props.search)

  onPlay: (e) ->
    @refs.video.play()
    @setState
      playing: true

  onChangeNewComment: (e) ->
    @setState
      newComment: e.target.value

  onComment: ->
    Store.newComment @props.itemId, @state.newComment
    @setState
      newComment: ''

  stopVideo: ->
    @setState
      playing: false

  preload: (dir) ->
    item = Store.state.itemsById[@props.itemId]
    if !item
      console.warn "Item not loaded: #{@props.itemId}"
      return

    newIndex = item.index + dir
    newItemId = Store.state.items[newIndex]
    if newItemId
      image = new Image()
      image.src = @largeURL newItemId

  largeURL: (itemId) ->
    item = Store.state.itemsById[itemId]
    if !item
      console.warn "Item not loaded: #{itemId}"
      return null

    size = if item.variety == 'video'
      'exploded'
    else
      'large'

    return "/data/resized/#{size}/#{itemId}.jpg"

  linkTo: (dir) ->
    item = Store.state.itemsById[@props.itemId]
    if !item
      console.warn "Item not loaded: #{@props.itemId}"
      return

    newIndex = item.index + dir
    newItemId = Store.state.items[newIndex]
    if newItemId
      return '#/items/' + newItemId

  render: ->
    # load prev and next indexes
    item = Store.getItem @props.itemId

    # make sure that the next batch is loaded if they are a fast clicker
    margin = 10

    if item
      Store.executeSearch item.index - margin, item.index + margin
      @preload 1
      @preload -1

    comments = Store.getComments(@props.itemId)

    nextLink = @linkTo 1
    prevLink = @linkTo -1

    <div className="details-window" onTouchStart={@onTouchStart} onTouchMove={@onTouchMove} onTouchEnd={@onTouchEnd}>
      {
        if item && item.variety == 'video'
          <video className="detailed-image" src={"/data/resized/stream/#{@props.itemId}.mp4"} ref="video" controls={@state.playing}} preload="none" poster={@largeURL(@props.itemId)}/>

        else
          <img ref="image" onClick={@onClose} className="detailed-image" src={@largeURL(@props.itemId)} />
      }

      {
        if item && item.variety == 'video' && !@state.playing
          <a className="control play-control" href="javascript:void(0)" onClick={@onPlay}>&#9654;</a>
      }
      {
        if prevLink
          <a className="control prev-control" href={prevLink} onClick={@stopVideo}>&larr;</a>
      }
      <a className="control close-control" href="javascript:void(0)" onClick={@onClose}>&times;</a>
      {
        if nextLink
          <a className="control next-control" href={nextLink} onClick={@stopVideo}>&rarr;</a>
      }
      <div className="tagbox">
        {
          if item
            item.tag_ids.map (tag_id) ->
              tag = Store.state.tagsById[tag_id]
              if tag
                tag_icon_url = "/data/resized/square/#{tag.icon}.jpg"
                <img title={tag.label} className="tag-icon" key={tag_id} src={tag_icon_url}/>
        }
      </div>
      <div className="comments">
        {
          comments.map (comment) ->
            <div key={comment.id} className="comment">
              {comment.text}<br/>
              <strong>{comment.user.name}</strong> &mdash;
              <em>{comment.created_at}</em>
            </div>
        }
        <div key="new" className="comment">
          <textarea placeholder="What a great picture!" value={@state.newComment} onChange={@onChangeNewComment}/>
          <button className="btn btn-default" onClick={@onComment}>Submit</button>
        </div>
      </div>
    </div>
