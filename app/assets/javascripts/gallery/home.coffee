pluralize = (count, obj) ->
  if count == 1
    "#{count.toLocaleString()} #{obj}"
  else
    "#{count.toLocaleString()} #{obj}s"

# Lazy loading state for activity items
lazyActivityState =
  loadedItems: new Set()
  observer: null

# Initialize intersection observer for lazy loading
initLazyLoading = ->
  return if lazyActivityState.observer

  lazyActivityState.observer = new IntersectionObserver (entries) ->
    entries.forEach (entry) ->
      if entry.isIntersecting
        activityId = entry.target.dataset.activityId
        if activityId
          lazyActivityState.loadedItems.add activityId
          Store.needsRedraw()
  , {
    threshold: 0.5,
    rootMargin: '50% 0px 50% 0px'
  }

# Cleanup observer when needed
cleanupLazyLoading = ->
  if lazyActivityState.observer
    lazyActivityState.observer.disconnect()
    lazyActivityState.observer = null

# Component for activity placeholder
component 'ActivityPlaceholder', (props) ->
  React.useEffect ->
    element = document.querySelector("[data-activity-id='#{props.activityId}']")
    if element && lazyActivityState.observer
      lazyActivityState.observer.observe element

    # Cleanup on unmount
    ->
      if element && lazyActivityState.observer
        lazyActivityState.observer.unobserve element
  , [props.activityId]

  <div
    className="activity-placeholder #{props.type}"
    data-activity-id={props.activityId}
    style={{
      height: props.estimatedHeight || '120px',
      backgroundColor: '#f8f9fa',
      border: '1px solid #e9ecef',
      borderRadius: '4px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      marginBottom: '15px',
      color: '#6c757d'
    }}
  >
    <div>
      <i className="fa fa-spinner fa-spin" style={{marginRight: '8px'}}></i>
      Loading activity...
    </div>
  </div>

component 'Home', ->
  recent = Store.fetchRecent()
  itemCounts = Store.fetchUnpublishedItemCounts()
  isLoadingActivity = Store.isLoadingActivity()

  # Initialize lazy loading when component mounts
  React.useEffect ->
    initLazyLoading()
    # Cleanup on unmount
    -> cleanupLazyLoading()
  , []

  <div className="container-fluid cheese-home">
    <h1>Welcome to HyperCheese</h1>

    <div>
      <div className="btn-group">
        <Link className="btn btn-primary" href="/search/">All Photos</Link>
      </div>
      {' '}
      {
        recent.sources.map (source) ->
          href = "/search/source:#{source.label}"
          <div key={source.path} className="btn-group">
            <Link className="btn btn-outline-secondary" href={href}>{source.label} Photos</Link>
          </div>
      }
    </div>
    <br/>
    <div>
      <div className="btn-group">
        <Link className="btn btn-outline-secondary" href="/tags/">Tags</Link>
      </div>
      {' '}
      <div className="btn-group">
        <Link className="btn btn-outline-secondary" href="/locations">Locations</Link>
      </div>
      {' '}
      <div className="btn-group">
        <a className="btn btn-outline-secondary" href="/faces/">Faces</a>
      </div>
      {' '}
      <Writer>
        <div className="btn-group">
          <Link className="btn btn-outline-secondary" href="/search/starred">My Stars</Link>
        </div>
        {' '}
        <div className="btn-group">
          <Link className="btn btn-outline-secondary" href="/search/unjudged%20sort:random">Judge Mode</Link>
        </div>
      </Writer>
    </div>
    <br/>
    <div>
      {
        if !itemCounts
          <div className="btn-group">
            <button className="btn btn-primary" disabled>
              <i className="fa fa-spinner fa-spin"></i> Loading...
            </button>
          </div>
          {' '}
          <div className="btn-group">
            <button className="btn btn-outline-secondary" disabled>
              <i className="fa fa-spinner fa-spin"></i> Loading...
            </button>
          </div>
        else
          <div>
            {
              if itemCounts.new_items > 0
                <div className="btn-group">
                  <Link className="btn btn-primary" href="/search/visibility:unknown">{itemCounts.new_items} New Item(s)</Link>
                </div>
            }
            {' '}
            {
              if itemCounts.private_items > 0
                <div className="btn-group">
                  <Link className="btn btn-outline-secondary" href="/search/visibility:unpublished">Your {itemCounts.private_items} Private Item(s)</Link>
                </div>
            }
          </div>
      }
    </div>

    <h2>Recent Activity</h2>
    <div className="recent-activity">
      {
        if isLoadingActivity
          <div style={{
            textAlign: 'center',
            padding: '40px',
            color: '#6c757d'
          }}>
            <i className="fa fa-spinner fa-spin fa-2x" style={{marginBottom: '10px'}}></i>
            <div>Loading recent activity...</div>
          </div>
        else
          img_for = (object) ->
            <Link href="/items/#{object.item_id}">
              <ItemImg id={object.item_id} />
            </Link>

          # Generate unique activity IDs and determine which items to load initially
          recent.activity.map (activity, index) ->
            activityId = "activity-#{index}"

            # Load first few items immediately, rest are lazy loaded
            shouldLoadImmediately = index < 3
            isLoaded = shouldLoadImmediately || lazyActivityState.loadedItems.has(activityId)

            unless isLoaded
              # Return placeholder for unloaded items
              activityType = 'comment' if activity.comment
              activityType = 'bullhorn' if activity.bullhorn
              activityType = 'group' if activity.item_group
              activityType = 'tagging' if activity.tagging
              activityType = 'face_detection' if activity.face_detection
              activityType = 'unidentified_faces' if activity.unidentified_faces
              activityType = 'unknown'

              estimatedHeight = switch activityType
                when 'comment', 'bullhorn' then '120px'
                when 'group' then '200px'
                when 'tagging', 'face_detection' then '100px'
                when 'unidentified_faces' then '150px'
                else '120px'

              return <ActivityPlaceholder
                key={activityId}
                activityId={activityId}
                type={activityType}
                estimatedHeight={estimatedHeight}
              />

            # Render actual activity content with proper key
            if comment = activity.comment
              <p className="clearfix comment" key={activityId}>
                {img_for comment}
                <span className="text">{comment.text}</span><br/>
                <em>&mdash; {comment.user.name}, {new Date(comment.created_at).toLocaleString()}</em>
              </p>
            else if bullhorn = activity.bullhorn
              <p className="clearfix bullhorn" key={activityId}>
                {img_for bullhorn}
                <span className="text"><i className="fa fa-bullhorn"></i></span><br/>
                <em>&mdash; {bullhorn.user.name}, {new Date(bullhorn.created_at).toLocaleString()}</em>
              </p>
            else if group = activity.item_group
              <div className="clearfix group" key={activityId}>
                <PhotoGroup group={group} />
                <div className="group-text">
                  <span className="text">
                    <Link href="/search/item:#{group.id_range}">
                      {
                        msg = []
                        if group.photo_count
                          msg.push pluralize(group.photo_count, "photo")
                        if group.video_count
                          msg.push pluralize(group.video_count, "video")
                        msg.join ' and '
                      }
                    </Link> added to {group.source}
                  </span><br/>
                  <em>&mdash; {new Date(group.created_at).toLocaleString()}</em>
                </div>
              </div>
            else if tagging = activity.tagging
              count = 0
              <div className="clearfix tagging" key={activityId}>
                <div className="tagging-list">
                  {
                    tagging.list.map (t) ->
                      count += t.count
                      tag = Store.state.tagsById[t.tag_id]
                      return unless tag
                      <Link href="/search/item:#{t.items}">
                        <Tag key={t.tag_id} tag={tag}>
                          +{t.count.toLocaleString()}
                        </Tag>
                      </Link>
                  }
                </div>
                {pluralize(count, "tag")} added <em>&mdash; {tagging.user?.name}, {new Date(tagging.created_at).toLocaleString()}</em>
              </div>
            else if face_detection = activity.face_detection
              count = 0
              <div className="clearfix tagging" key={activityId}>
                <div className="tagging-list">
                  {
                    face_detection.list.map (f) ->
                      count += f.face_count
                      tag = Store.state.tagsById[f.tag_id]
                      return unless tag
                      <Link href="/search/item:#{f.items}">
                        <Tag key={f.tag_id} tag={tag}>
                          +{f.face_count.toLocaleString()}
                        </Tag>
                      </Link>
                  }
                </div>
                {pluralize(count, "face")} detected <em>&mdash; {new Date(face_detection.created_at).toLocaleString()}</em>
              </div>
            else if unidentified_faces = activity.unidentified_faces
              <div className="clearfix unidentified-faces" key={activityId}>
                <div className="face-grid">
                  {
                    unidentified_faces.faces.map (face) ->
                      face_url = "/data/faces/#{face.item_id}-#{face.face_id}-#{face.item_code}.jpg"

                      <Link href="/items/#{face.item_id}">
                        <img key={face.face_id} className="face-thumb" src={face_url} title="Unidentified person - click to view item"/>
                      </Link>
                  }
                </div>
                {pluralize(unidentified_faces.face_count, "unknown face")} detected <em>&mdash; {new Date(unidentified_faces.created_at).toLocaleString()}</em>
              </div>
      }
    </div>
  </div>
