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
          {fact 'location-arrow', <GPSCoord exif={details.exif}/>}
          {
            if details.width && details.height && !details.exif && !details.probe
              res = <span>{details.width}&times;{details.height} {(details.width*details.height/1000000).toFixed(1)} MP</span>
              fact 'camera', res
          }
          {
            if exif = details.exif
              data = []
              data.push <div>{details.width}&times;{details.height} {(details.width*details.height/1000000).toFixed(1)} MP</div>
              data.push <div key="artist">{exif.artist}</div> if exif.artist
              data.push <div key="model">{exif.model}</div>
              data.push <div key="iso">ISO {exif.iso_speed_ratings}</div>
              data.push <div key="flen">{frac exif.focal_length} mm</div>
              data.push <div key="fnum">&fnof;/{frac exif.f_number}</div>
              data.push <div key="time">{exif.exposure_time} sec</div>
              fact 'camera', data
          }
          {
            if probe = details.probe
              data = []
              if details.height == 360 || details.width == 360
                data.push <div key="res">360p</div>
              else if details.height == 480 || details.width == 480
                data.push <div key="res">480p</div>
              else if details.height == 720 || details.width == 720
                data.push <div key="res">720p</div>
              else if details.height == 1080 || details.width == 1080
                data.push <div key="res">1080p</div>
              else if details.width == 2160 || details.width == 2160
                data.push <div key="res">4K</div>
              else
                data.push <div key="res">{details.width}&times;{details.height}</div>
              data.push <div key="dur">{Math.round(probe.duration)} sec</div>
              data.push <div key="codec">{probe.codec}</div>
              data.push <div key="frate">{frac probe.rate} fps</div>
              data.push <div key="bitrate">{(details.filesize * 8 / 1000000 / probe.duration).toFixed(1)} mbps</div> if details.filesize && probe.duration
              fact 'video-camera', data
          }
          {
            if details.aesthetics_score?
              fact 'paint-brush', details.aesthetics_score.toFixed(1)
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
                {
                  if details.pretty_size
                    details.pretty_size
                }
              </div>

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
              tag.icon_id = @props.item.id
              tag.icon_code = @props.item.code
              Store.updateTag tag

            age = details.ages[tag_id]
            <div key={tag_id}>
              <TagLink tag={tag}/>
              {' '}
              <Writer>
                <a href="javascript:void(0)" onClick={setTagIcon} title="Set current photo as icon for this tag">
                  <i className="fa fa-link"/>
                </a>
              </Writer>
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
      {
        if details.faces
          <p>Experimental Face Matching:</p>
      }
      <div className="faces">
        {
          (details.faces || []).map (face) ->
            <div key={face.id} className="face">
              <a href="/faces/#{face.id}">
                <img src={"/data/faces/#{item.id}-#{face.id}-#{item.code}.jpg"}/>
              </a>
              <br/>
              {
                tag = Store.state.tagsById[ face.cluster_tag_id ]
                if tag
                  <React.Fragment>
                    <strong>{tag.alias || tag.label}</strong>
                    <br/>
                    {(face.similarity * 100).toFixed(1)}%
                  </React.Fragment>
              }
            </div>
        }
      </div>
      <Writer>
        <form key="new" className="comment" onSubmit={@onComment}>
          <textarea placeholder="What a great picture!" value={@state.newComment} onChange={@onChangeNewComment}/>
          <br/>
          <button className="btn btn-default">Submit</button>
        </form>
      </Writer>
    </div>
