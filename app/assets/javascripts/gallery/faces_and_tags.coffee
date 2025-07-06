component 'FacesAndTags', ({item, details}) ->
  seenTags = new Set
  [showingTrail, setShowingTrail] = useState(null)

  showTrailDetail = (trail) ->
    setShowingTrail(trail)

  hideTrailDetail = ->
    setShowingTrail(null)

  <div className="faces-and-tags">
    {
      # Show face trails for videos, individual faces for photos
      if item.variety == 'video'
        (details.face_trails || []).map (trail) ->
          tag_names = trail.tag_names || []
          primary_tag_name = trail.primary_tag_name
          rep_face = trail.representative_face
          
          # Track seen tags
          if rep_face?.tag_id
            seenTags.add rep_face.tag_id
          if rep_face?.cluster_tag_id
            seenTags.add rep_face.cluster_tag_id

          <div key={trail.id} className="face-trail">
            <div className="trail-image" onClick={() => showTrailDetail(trail)}>
              {
                if rep_face
                  <img src={"/data/faces/#{item.id}-#{rep_face.id}-#{item.code}.jpg"}/>
                else
                  <div className="no-representative">Trail</div>
              }
            </div>
            <div className="trail-info">
              <div className="trail-names">
                {
                  if tag_names.length > 0
                    tag_names.map (name, index) ->
                      style = if name == primary_tag_name then {fontWeight: 'bold'} else {}
                      <span key={index} style={style}>
                        {name}
                        {if index < tag_names.length - 1 then ', ' else ''}
                      </span>
                  else
                    <em>Unknown</em>
                }
              </div>
              <div className="trail-meta">
                <small>
                  {Math.round(trail.start_timestamp, 1)}s - {Math.round(trail.end_timestamp, 1)}s
                  ({trail.face_count} frames, {trail.embedding_face_count} embeddings)
                </small>
              </div>
            </div>
          </div>
      else
        (details.faces || []).map (face) ->
          tag = null
          tag_id = face.tag_id || face.cluster_tag_id

          if tag_id
            seenTags.add tag_id
            tag = Store.state.tagsById[tag_id]

          <div key={face.id} className="face">
            <a href="/faces/#{face.id}">
              <img src={"/data/faces/#{item.id}-#{face.id}-#{item.code}.jpg"}/>
            </a>
            <div>
              {tag?.alias || tag?.label}
              <br/>
              {
                <em>
                  {
                    if face.cluster_tag_id
                      "#{Math.round(face.similarity * 100, 1)}%"
                  }
                </em>
              }
              <br/>
              {
                age = details.ages[tag_id]
                if age
                  <em>({age})</em>
              }
            </div>
          </div>
    }
    {
      item.tag_ids.map (tag_id) ->
        return null if seenTags.has tag_id
        tag = Store.state.tagsById[tag_id]
        if tag
          setTagIcon = ->
            tag.icon_id = item.id
            tag.icon_code = item.code
            Store.updateTag tag

          age = details.ages[tag_id]
          <div className="tag" key={tag_id}>
            <TagLink tag={tag}/>
            {' '}
            <Writer>
              <button onClick={setTagIcon} title="Set current photo as icon for this tag">
                <i className="fa fa-link"/>
              </button>
            </Writer>
            {' '}
            <div>
              <strong>{tag.alias || tag.label}</strong>
              {
                if age
                  <em>({age})</em>
              }
            </div>
          </div>
    }
    {
      # Trail detail dialog
      if showingTrail
        <TrailDetailDialog 
          trail={showingTrail} 
          item={item} 
          details={details}
          onClose={hideTrailDetail}
        />
    }
  </div>
