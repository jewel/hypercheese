@GalleryApp = React.createClass
  componentDidMount: ->
    Store.onChange =>
      @forceUpdate()

  render: ->
    <div className="react-wrapper">
      <NavBar/>
      <Results/>
    </div>
