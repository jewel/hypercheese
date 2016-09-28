@Home = React.createClass
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
                        msg.push "#{group.photo_count} photos"
                      if group.video_count
                        msg.push "#{group.video_count} videos"
                      msg.join ' and '
                    }
                  </Link> added to {group.source}
                </span><br/>
                <em>&mdash; {new Date(group.created_at).toLocaleString()}</em>
              </p>
        }
      </div>
    </div>
