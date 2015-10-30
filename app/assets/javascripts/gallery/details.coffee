@Details = React.createClass
  getInitialState: ->
    newComment: ''
    playing: false

  onClose: (e) ->
    e.stopPropagation()
    @props.updateHighlight @props.itemId

    if @props.search == ''
      window.location.hash = '/'
    else
      window.location.hash = '/search/' + encodeURI(@props.search)

  onVideoClick: (e) ->
    if !@state.playing
      return @onClose(e)

  onNext: (e) ->
    e.stopPropagation()
    @moveTo 1

  onPrev: (e) ->
    e.stopPropagation()
    @moveTo -1

  onPlay: (e) ->
    @refs.video.getDOMNode().play()
    @setState
      playing: true

  onChangeNewComment: (e) ->
    @setState
      newComment: e.target.value

  onComment: ->
    Store.newComment @props.itemId, @state.newComment
    @setState
      newComment: ''

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

  moveTo: (dir) ->
    item = Store.state.itemsById[@props.itemId]
    if !item
      console.warn "Item not loaded: #{@props.itemId}"
      return

    newIndex = item.index + dir
    newItemId = Store.state.items[newIndex]
    if newItemId
      window.location.hash = '/items/' + newItemId

  render: ->
    # load prev and next indexes
    item = Store.getItem @props.itemId
    if !item
      return <div>Loading image</div>

    # make sure that the next batch is loaded if they are a fast clicker
    margin = 10

    Store.executeSearch item.index - margin, item.index + margin
    @preload 1
    @preload -1

    comments = Store.getComments(@props.itemId)

    <div className="details-window">
      <a className="control prev-control" href="javascript:void(0)" onClick={@onPrev}>&larr;</a>
      <a className="control close-control" href="javascript:void(0)" onClick={@onClose}>&times;</a>
      <a className="control next-control" href="javascript:void(0)" onClick={@onNext}>&rarr;</a>
      {
        if item.variety == 'video' && !@state.playing
          <a className="control play-control" href="javascript:void(0)" onClick={@onPlay}>&#9654;</a>
      }
      {
        if item.variety == 'video'
          <video onClick={@onVideoClick} className="detailed-image" src={"/data/resized/stream/#{@props.itemId}.mp4"} ref="video" preload="none" controls={@state.playing} poster={@largeURL(@props.itemId)} />

        else
          <img onClick={@onClose} className="detailed-image" src={@largeURL(@props.itemId)} />
      }
      <div className="tagbox">
        {
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
