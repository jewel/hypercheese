@Info = React.createClass
  getInitialState: ->
    newComment: ''

  onChangeNewComment: (e) ->
    @setState
      newComment: e.target.value

  onComment: (e) ->
    e.preventDefault()
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

    <div className="info">
      <p>
        <a href="javascript:void(0)" onClick={@props.onInfo}><i className="btn fa fa-close"/></a>
      </p>
      <table className="table">
        <tbody>
          {fact 'calendar', details.taken}
          {fact 'camera', details.camera}
          {fact 'location-arrow', details.location}
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
                <a href="/items/download?ids=#{@props.item.id}">
                  <i className="fa fa-download"/> Download
                </a>
              </div>
            </td>
          </tr>
          <tr>
            <th><i className="fa fa-star-o"/></th>
            <td>
              {
                details.stars.map (user) =>
                  <div key={user.id}>
                    {user.name || "user ##{user.id}"}
                  </div>
              }
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
              <Tag tag=tag />
              {' '}
              <a href="javascript:void(0)" onClick=setTagIcon title="Set current photo as icon for this tag">
                <i className="fa fa-link"/>
              </a>
              {' '}
              <strong>{tag.label}</strong>
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
              <strong>{comment.user.name}</strong> &mdash;
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
