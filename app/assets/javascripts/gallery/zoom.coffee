component 'Zoom', ({small}) ->
  [zoom, setZoomState] = useState Store.state.zoom

  onChange = (e) ->
    setZoom e.target.value

  setZoom = (val) ->
    setZoomState val
    Store.setZoom val

  shrink = (e) ->
    e.preventDefault()
    e.stopPropagation()
    newZoom = zoom - 1
    newZoom = 1 if newZoom < 1
    setZoom newZoom

  grow = (e) ->
    e.preventDefault()
    e.stopPropagation()
    newZoom = zoom + 1
    newZoom = 10 if newZoom > 10
    setZoom newZoom

  button = (action, el) ->
    if small
      <button onClick={action} className="btn btn-default">{el}</button>
    else
      el

  <form className="navbar-form navbar-right hidden-xs" onSubmit={-> false}>
    {button shrink, <i onClick={shrink} className="fa fa-search-minus"/>}
    {' '}
    {
      if !small
        <input className="form-control" type="range" min="1" max="10" step="1" value={zoom} onChange={onChange}/>
    }
    {' '}
    {button grow, <i onClick={grow} className="fa fa-search-plus"/>}
  </form>
