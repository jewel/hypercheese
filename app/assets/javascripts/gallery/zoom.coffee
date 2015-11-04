@Zoom = React.createClass
  getInitialState: ->
    zoom: Store.state.zoom

  onChange: (e) ->
    @setState
      zoom: e.target.value
    Store.setZoom e.target.value

  render: ->
    <form className="navbar-form navbar-right">
      <i className="fa fa-search-minus"/>
      {' '}
      <input className="form-control" type="range" min="1" max="10" step="1" defaultValue="5" value={@state.zoom} onChange={@onChange}/>
      {' '}
      <i className="fa fa-search-plus"/>
    </form>
