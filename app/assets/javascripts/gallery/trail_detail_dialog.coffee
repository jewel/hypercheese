component 'TrailDetailDialog', ({trail, item, details, onClose}) ->
  [trailFaces, setTrailFaces] = useState([])
  [loading, setLoading] = useState(true)

  useEffect ->
    loadTrailFaces()
  , [trail.id]

  loadTrailFaces = ->
    setLoading(true)
    # In a real implementation, we'd make an API call to get all faces for this trail
    # For now, we'll simulate it with the available data
    fetch("/api/face_trails/#{trail.id}/faces")
      .then (response) -> response.json()
      .then (data) ->
        setTrailFaces(data.faces || [])
        setLoading(false)
      .catch (error) ->
        console.error('Error loading trail faces:', error)
        setLoading(false)

  <div className="trail-detail-overlay" onClick={onClose}>
    <div className="trail-detail-dialog" onClick={(e) -> e.stopPropagation()}>
      <div className="dialog-header">
        <h3>Face Trail Details</h3>
        <button className="close-button" onClick={onClose}>
          <i className="fa fa-times"/>
        </button>
      </div>
      
      <div className="dialog-content">
        <div className="trail-summary">
          <h4>
            {
              if trail.primary_tag_name
                trail.primary_tag_name
              else
                "Unknown Person"
            }
          </h4>
          <div className="trail-tags">
            {
              if trail.tag_names && trail.tag_names.length > 0
                <div>
                  <strong>All detected names:</strong>
                  {' '}
                  {
                    trail.tag_names.map (name, index) ->
                      <span key={index}>
                        {name}
                        {if index < trail.tag_names.length - 1 then ', ' else ''}
                      </span>
                  }
                </div>
            }
          </div>
          <div className="trail-info">
            <div>Duration: {Math.round(trail.start_timestamp, 1)}s - {Math.round(trail.end_timestamp, 1)}s</div>
            <div>Total frames: {trail.face_count}</div>
            <div>Faces with embeddings: {trail.embedding_face_count}</div>
          </div>
        </div>

        <div className="trail-faces">
          {
            if loading
              <div className="loading">Loading faces...</div>
            else if trailFaces.length > 0
              <div className="faces-grid">
                {
                  trailFaces.map (face) ->
                    <div key={face.id} className="trail-face">
                      <a href="/faces/#{face.id}">
                        <img src={"/data/faces/#{item.id}-#{face.id}-#{item.code}.jpg"}/>
                      </a>
                      <div className="face-timestamp">
                        {Math.round(face.timestamp, 1)}s
                      </div>
                    </div>
                }
              </div>
            else
              <div className="no-faces">No faces with embeddings found for this trail.</div>
          }
        </div>
      </div>
    </div>
  </div>