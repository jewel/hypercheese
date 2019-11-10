@Home = createReactClass
  pluralize: (count, obj) ->
    if count == 1
      "#{count} #{obj}"
    else
      "#{count} #{obj}s"

  render: ->
    recent = Store.fetchRecent()
    <div className="container-fluid cheese-home">
      <h1>Welcome to HyperCheese</h1>

      <div>
        <div className="btn-group">
          <Link className="btn btn-default btn-primary" href="/search/">All Photos</Link>
        </div>
        {' '}
        <div className="btn-group">
          {
            recent.sources.map (source) =>
              href = "/search/source:#{source.label}"
              <Link key={source.path} className="btn btn-default" href=href>{source.label} Photos</Link>
          }
        </div>
      </div>
      <br/>
      <div>
        <div className="btn-group">
          <Link className="btn btn-default" href="/tags/">Tags</Link>
        </div>
        {' '}
        <div className="btn-group">
          <Link className="btn btn-default" href="/search/starred">My Stars</Link>
        </div>
        {' '}
        <div className="btn-group">
          <Link className="btn btn-default" href="/search/unjudged%20sort:random">Judge Mode</Link>
        </div>
      </div>
      <br/>
      <div>
        {
          if recent.new_items > 0
            <div className="btn-group">
              <Link className="btn btn-default btn-primary" href="/search/visibility:unknown">{recent.new_items} New Item(s)</Link>
            </div>
        }
        {' '}
        {
          if recent.private_items > 0
            <div className="btn-group">
              <Link className="btn btn-default" href="/search/visibility:unpublished">Your {recent.private_items} Private Item(s)</Link>
            </div>
        }
      </div>

      <h2>Recent Activity</h2>
      <div className="recent-activity">
        {
          recent.activity.map (activity) =>
            if comment = activity.comment
              user = Store.state.userById
              <p className="clearfix comment" key="c#{comment.id}">
                <Link href="/items/#{comment.item_id}">
                  <img src="/data/resized/square/#{comment.item_id}.jpg" />
                </Link>
                <span className="text">{comment.text}</span><br/>
                <em>&mdash; {comment.user.name}, {new Date(comment.created_at).toLocaleString()}</em>
              </p>
            else if bullhorn = activity.bullhorn
              user = Store.state.userById
              <p className="clearfix bullhorn" key="s#{bullhorn.id}">
                <Link href="/items/#{bullhorn.item_id}">
                  <img src="/data/resized/square/#{bullhorn.item_id}.jpg" />
                </Link>
                <span className="text"><i className="fa fa-bullhorn"></i></span><br/>
                <em>&mdash; {bullhorn.user.name}, {new Date(bullhorn.created_at).toLocaleString()}</em>
              </p>
            else if group = activity.item_group
              <p className="clearfix group" key="g#{group.item_id}">
                <Link href="/items/#{group.item_id}">
                  <img src="/data/resized/square/#{group.item_id}.jpg" />
                </Link>
                <span className="text">
                  <Link href="/search/item:#{group.ids}">
                    {
                      msg = []
                      if group.photo_count
                        msg.push @pluralize(group.photo_count, "photo")
                      if group.video_count
                        msg.push @pluralize(group.video_count, "video")
                      msg.join ' and '
                    }
                  </Link> added to {group.source}
                </span><br/>
                <em>&mdash; {new Date(group.created_at).toLocaleString()}</em>
              </p>
            else if tagging = activity.tagging
              <div className="clearfix tagging" key="t#{tagging.created_at}">
                <div className="tagging-list">
                  {
                    tagging.list.map (t) =>
                      tag = Store.state.tagsById[t.tag_id]
                      return unless tag
                      <Tag key=t.tag_id tag=tag>
                        +{t.count}
                      </Tag>
                  }
                </div>
                <em>&mdash; {new Date(tagging.created_at).toLocaleString()}</em>
              </div>
        }
      </div>
    </div>
