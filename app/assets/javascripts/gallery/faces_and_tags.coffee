component 'FacesAndTags', ({item, details}) ->
  seenTags = new Set

  <div className="faces-and-tags">
    {
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
  </div>
