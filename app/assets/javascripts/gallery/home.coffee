@Home = React.createClass
  render: ->
    recent = Store.fetchRecent()
    <div className="container-fluid cheese-home">
      <h1>Welcome to HyperCheese</h1>

      <p>
        <a className="btn btn-default btn" href="#/search/">View All Photos</a>
      </p>

      <h2>Recent Activity</h2>
      {
        recent.activity.map (activity) =>
          if comment = activity.comment
            <div key="c#{comment.id}">
              New Comment: {comment.text}
            </div>
          else if item = activity.item
            <div key="i#{item.id}">
              New Photo: <img src="/data/resized/square/#{item.id}.jpg"/>
            </div>
      }
    </div>
