@Info = createReactClass
  getInitialState: ->
    newComment: ''

  componentDidMount: ->
    Store.state.openStack.push 'info'

  onChangeNewComment: (e) ->
    @setState
      newComment: e.target.value

  onComment: (e) ->
    e.preventDefault()
    return unless @state.newComment
    Store.newComment @props.item.id, @state.newComment
    @setState
      newComment: ''

  render: ->
    item = @props.item
    details = Store.getDetails item.id

    fact = (label, info) ->
      <tr key={label}>
        <th><i className="fa fa-#{label}"/></th>
        <td>{info}</td>
      </tr>

    frac = (str) ->
      return null unless str
      parts = str.split '/'
      parts[0] / parts[1]

    <div className="info">
      <a className="btn pull-right" href="javascript:void(0)" onClick={@props.onInfo}><i className="fa fa-close"/></a>
      <table className="table">
        <tbody>
          {fact 'calendar', new Date(details.taken).toLocaleString()}
          {fact 'location-arrow', details.location}
          {
            if exif = details.exif
              data = []
              data.push <div key="model">{exif.model}</div>
              data.push <div key="iso">ISO {exif.iso_speed_ratings}</div>
              data.push <div key="flen">{frac exif.focal_length} mm</div>
              data.push <div key="fnum">&fnof;/{frac exif.f_number}</div>
              data.push <div key="time">{exif.exposure_time} sec</div>
              fact 'camera', data
          }
          <tr>
            <th><i className="fa fa-folder-o"/></th>
            <td>
              {
                details.paths.map (path) =>
                  <div key={path}>
                    {path}
                  </div>
              }
              <div>
                <a href="/api/items/download?ids=#{@props.item.id}">
                  <i className="fa fa-download"/> Download
                </a>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
      {
        item.tag_ids.map (tag_id) =>
          tag = Store.state.tagsById[tag_id]
          if tag
            setTagIcon = =>
              tag.icon = @props.item.id
              Store.updateTag tag

            age = details.ages[tag_id]
            <div key={tag_id}>
              <TagLink tag=tag />
              {' '}
              <a href="javascript:void(0)" onClick=setTagIcon title="Set current photo as icon for this tag">
                <i className="fa fa-link"/>
              </a>
              {' '}
              <strong>{tag.alias || tag.label}</strong>
              {' '}
              {
                if age
                  <em>({age})</em>
              }
            </div>
      }
      {
        details.comments.map (comment) ->
          <p key={comment.id} className="comment">
            {comment.text}<br/>
            <small>
              <strong>{comment.username}</strong> &mdash;
              <em>{new Date(comment.created_at).toLocaleString()}</em>
            </small>
          </p>
      }
      <form key="new" className="comment" onSubmit={@onComment}>
        <textarea placeholder="What a great picture!" value={@state.newComment} onChange={@onChangeNewComment}/>
        <br/>
        <button className="btn btn-default">Submit</button>
      </form>
    </div>
