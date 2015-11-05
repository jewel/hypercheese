@Zoom = React.createClass
  getInitialState: ->
    zoom: Store.state.zoom

  onChange: (e) ->
    @setZoom e.target.value

  setZoom: (val) ->
    @setState
      zoom: val
    Store.setZoom val

  shrink: (e) ->
    e.preventDefault()
    e.stopPropagation()
    zoom = @state.zoom - 1
    zoom = 1 if zoom < 1
    @setZoom zoom

  grow: (e) ->
    e.preventDefault()
    e.stopPropagation()
    zoom = @state.zoom + 1
    zoom = 10 if zoom > 10
    @setZoom zoom

  render: ->
    button = (action, el) =>
      if @props.small
        <button onClick=action className="btn btn-default">{el}</button>
      else
        el

    <form className="navbar-form navbar-right" onSubmit={-> false}>
      {button @shrink, <i onClick={@shrink} className="fa fa-search-minus"/>}
      {' '}
      {
        if !@props.small
          <input className="form-control" type="range" min="1" max="10" step="1" defaultValue="5" value={@state.zoom} onChange={@onChange}/>
      }
      {' '}
      {button @grow, <i onClick={@grow} className="fa fa-search-plus"/>}
    </form>
