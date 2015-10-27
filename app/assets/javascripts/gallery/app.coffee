#= require ./navbar
#= require ./item

@GalleryApp = React.createClass
  componentDidMount: ->
    Store.onChange =>
      @forceUpdate()

  render: ->
    <div className="react-wrapper">
      <Results/>
    </div>
