@Home = React.createClass
  render: ->
    recent = Store.fetchRecent()
    <div className="container-fluid cheese-home">
      <h1>Welcome to HyperCheese</h1>

      <div>
        <div className="btn-group">
          <a className="btn btn-default btn-primary" href="#/search/">All Photos</a>
        </div>
        {' '}
        <div className="btn-group">
          {
            recent.sources.map (source) =>
              href = "#/search/source:#{source.label}"
              <a key={source.path} className="btn btn-default" href=href>{source.label} Photos</a>
          }
        </div>
      </div>
      <br/>
      <div>
        <div className="btn-group">
          <a className="btn btn-default" href="#/tags/">Tags</a>
        </div>
      </div>

      <h2>Recent Activity</h2>
      <div className="recent-activity">
        {
          recent.activity.map (activity) =>
            if comment = activity.comment
              user = Store.state.userById
              <p className="clearfix comment" key="c#{comment.id}">
                <a href="#/items/#{comment.item_id}">
                  <img src="/data/resized/square/#{comment.item_id}.jpg" />
                </a>
                <span className="text">{comment.text}</span><br/>
                <em>&mdash; {comment.user.name}, {new Date(comment.created_at).toLocaleString()}</em>
              </p>
            else if star = activity.star
              user = Store.state.userById
              <p className="clearfix star" key="s#{star.id}">
                <a href="#/items/#{star.item_id}">
                  <img src="/data/resized/square/#{star.item_id}.jpg" />
                </a>
                <span className="text"><i className="fa fa-star"></i></span><br/>
                <em>&mdash; {star.user.name}, {new Date(star.created_at).toLocaleString()}</em>
              </p>
            else if group = activity.item_group
              <p className="clearfix group" key="g#{group.item_id}">
                <a href="#/items/#{group.item_id}">
                  <img src="/data/resized/square/#{group.item_id}.jpg" />
                </a>
                <span className="text">
                  <a href="#/search/item:#{group.ids}">
                    {
                      msg = []
                      if group.photo_count
                        msg.push "#{group.photo_count} photos"
                      if group.video_count
                        msg.push "#{group.video_count} videos"
                      msg.join ' and '
                    }
                  </a> added to {group.source}
                </span><br/>
                <em>&mdash; {new Date(group.created_at).toLocaleString()}</em>
              </p>
        }
      </div>
    </div>
