@Info = React.createClass
  getInitialState: ->
    newComment: ''

  onChangeNewComment: (e) ->
    @setState
      newComment: e.target.value

  onComment: ->
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
        <a href="javascript:void(0)"><i className="fa fa-close"/></a>
      </p>
      <table className="table">
        <tbody>
          {fact 'calendar', details.taken}
          {fact 'camera', details.camera}
          {fact 'location-arrow', details.location}
          <tr key='folder-o'>
            <th><i className="fa fa-folder-o"/></th>
            <td>
              {
                first = true
                details.paths.map (path) =>
                  f = first
                  first = false

                  <div key={path}>
                    {path}
                    {' '}
                    {
                      if f
                        <a href="/items/download?ids=#{@props.item.id}">
                          <i className="fa fa-download"/>
                        </a>
                    }
                  </div>
              }
            </td>
          </tr>
          {fact 'star-o', 'John'}
        </tbody>
      </table>
      {
        item.tag_ids.map (tag_id) ->
          tag = Store.state.tagsById[tag_id]
          if tag
            tag_icon_url = "/data/resized/square/#{tag.icon}.jpg"
            age = details.ages[tag_id]
            <p key={tag_id}>
              <img className="tag-icon" src={tag_icon_url}/>
              {' '}
              <strong>{tag.label}</strong>
              {' '}
              {
                if age
                  <em>({age})</em>
              }
            </p>
      }
      {
        details.comments.map (comment) ->
          <p key={comment.id} className="comment">
            {comment.text}<br/>
            <small>
              <strong>{comment.user.name}</strong> &mdash;
              <em>{comment.created_at}</em>
            </small>
          </p>
      }
      <form key="new" className="comment">
        <textarea placeholder="What a great picture!" value={@state.newComment} onChange={@onChangeNewComment}/>
        <br/>
        <button className="btn btn-default" onClick={@onComment}>Submit</button>
      </form>
    </div>
