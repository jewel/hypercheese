@Zoom = React.createClass
  getInitialState: ->
    zoom: Store.state.zoom

  onChange: (e) ->
    @setZoom e.target.value

  setZoom: (val) ->
    @setState
      zoom: val
    Store.setZoom val

  shrink: ->
    zoom = @state.zoom - 1
    zoom = 1 if zoom < 1
    @setZoom zoom

  grow: ->
    zoom = @state.zoom + 1
    zoom = 10 if zoom > 10
    @setZoom zoom

  render: ->
    <form className="navbar-form navbar-right">
      <i onClick={@shrink} className="fa fa-search-minus"/>
      {' '}
      {
        if !@props.small
          <input className="form-control" type="range" min="1" max="10" step="1" defaultValue="5" value={@state.zoom} onChange={@onChange}/>
      }
      {' '}
      <i onClick={@grow} className="fa fa-search-plus"/>
    </form>
