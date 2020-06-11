@Info = createReactClass
  render: ->
    item = @props.item
    details = item # in the share interface this is currently the same thing

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
              data.push <div key="artist">{exif.artist}</div> if exif.artist
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
              {item.filename}
              {' '}
              <a href="/shares/#{Store.state.shareCode}/download_item/#{@props.item.id}">
                <i className="fa fa-download"/> Download
              </a>
            </td>
          </tr>
        </tbody>
      </table>
      {
        item.tags_with_labels.map (tag) =>
          [icon_id, icon_code, label] = tag
          <div key={icon_id}>
            <Tag icon_id=icon_id icon_code=icon_code />
            {' '}
            <strong>{label}</strong>
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
    </div>
