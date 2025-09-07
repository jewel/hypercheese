pluralize = (count, obj) ->
  if count == 1
    "#{count.toLocaleString()} #{obj}"
  else
    "#{count.toLocaleString()} #{obj}s"

component 'Home', ->
  recent = Store.fetchRecent()
  itemCounts = Store.fetchUnpublishedItemCounts()
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
        img_for = (object) ->
          <Link href="/items/#{object.item_id}">
            <ItemImg id={object.item_id} />
          </Link>

        recent.activity.map (activity) ->
          if comment = activity.comment
            <p className="clearfix comment" key="c#{comment.id}">
              {img_for comment}
              <span className="text">{comment.text}</span><br/>
              <em>&mdash; {comment.user.name}, {new Date(comment.created_at).toLocaleString()}</em>
            </p>
          else if bullhorn = activity.bullhorn
            <p className="clearfix bullhorn" key="s#{bullhorn.id}">
              {img_for bullhorn}
              <span className="text"><i className="fa fa-bullhorn"></i></span><br/>
              <em>&mdash; {bullhorn.user.name}, {new Date(bullhorn.created_at).toLocaleString()}</em>
            </p>
          else if group = activity.item_group
            <div className="clearfix group" key="g#{group.item_id}">
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
            <div className="clearfix tagging" key="t#{tagging.created_at}">
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
      }
    </div>
  </div>
