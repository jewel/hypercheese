@Home = React.createClass
  render: ->
    recent = Store.fetchRecent()
    <div className="container-fluid cheese-home">
      <h1>Welcome to HyperCheese</h1>

      <p>
        <a className="btn btn-default btn" href="#/search/">View All Photos</a>
      </p>

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
        }
      </div>
    </div>
