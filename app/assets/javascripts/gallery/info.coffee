component 'Info', ({item, isVisible, containerRef}) ->
  [newComment, setNewComment] = useState ''
  [isGeotagging, setIsGeotagging] = useState false

  onChangeNewComment = (e) ->
    setNewComment e.target.value

  onComment = (e) ->
    e.preventDefault()
    return unless newComment
    Store.newComment item.id, newComment
    setNewComment ''

  onStartGeotagging = ->
    setIsGeotagging true

  onCancelGeotagging = ->
    setIsGeotagging false

  onSaveGeotag = (locationData) ->
    fetch("/api/items/#{item.id}/geotag", {
      method: 'POST'
      headers: {
        'Content-Type': 'application/json'
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
      }
      body: JSON.stringify(locationData)
    })
    .then (response) -> response.json()
    .then (data) ->
      setIsGeotagging false
      # Update the item in the store
      Store.updateItem data
    .catch (error) ->
      console.error 'Error saving geotag:', error

  neighbor = (dir) ->
    newIndex = item.index + dir
    Store.state.items[newIndex]

  if item && isVisible
    details = Store.getDetails item.id

    # preload neighbors' details
    Store.getDetails neighbor(-1)
    Store.getDetails neighbor(1)
  else
    details = { comments: [], paths: [], ages: {} }

  fact = (label, info) ->
    <tr key={label}>
      <th><i className="fa fa-#{label}"/></th>
      <td>{info}</td>
    </tr>

  frac = (str) ->
    return null unless str
    parts = str.split '/'
    parts[0] / parts[1]

  <div className="info" ref={containerRef}>
    <table className="table">
      <tbody>
        <tr>
          <th><i className="fa fa-folder-o"/></th>
          <td>
            {
              details.paths.map (path) ->
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
              <a href="/api/items/download?ids=#{item.id}">
                <i className="fa fa-download"/> Download
              </a>
            </div>
          </td>
        </tr>
        {fact 'calendar', new Date(details.taken).toLocaleString()}
        {
          fact('location-arrow',
            <React.Fragment>
              <GeotaggingMap 
                item={item} 
                exif={details.exif} 
                isGeotagging={isGeotagging}
                onSave={onSaveGeotag}
                onCancel={onCancelGeotagging}
              />
              <GPSCoord exif={details.exif}/>
              {
                if details.locations?.length > 0
                  <React.Fragment>
                    <br/>
                    {
                      locations = details.locations.slice(0)
                      locations.reverse()
                      locations.join(", ")
                    }
                  </React.Fragment>
              }
              {
                unless isGeotagging
                  <div className="geotag-button-container">
                    <button 
                      className="btn btn-sm btn-outline-primary"
                      onClick={onStartGeotagging}
                    >
                      <i className="fa fa-map-marker"/> {if item.latitude && item.longitude then 'Edit Location' else 'Add Location'}
                    </button>
                  </div>
              }
            </React.Fragment>
          )
        }
        {
          if details.width && details.height && !details.exif && !details.probe
            res = <span>{details.width}&times;{details.height} {(details.width*details.height/1000000).toFixed(1)} MP</span>
            fact 'camera', res
        }
        {
          if exif = details.exif
            data = []
            data.push <div key="dims">{details.width}&times;{details.height} {(details.width*details.height/1000000).toFixed(1)} MP</div>
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
      </tbody>
    </table>
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
      if isVisible
        <FacesAndTags item={item} details={details}/>
    }
    <Writer>
      <form key="new" className="comment" onSubmit={onComment}>
        <textarea placeholder="What a great picture!" value={newComment} onChange={onChangeNewComment}/>
        <br/>
        <button className="btn btn-default">Submit</button>
      </form>
    </Writer>
    {
      if isVisible
        <SimilarPhotos key={item.id} itemId={item.id}/>
    }
  </div>
