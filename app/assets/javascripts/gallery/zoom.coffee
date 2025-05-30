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
      <button onClick={action} className="btn btn-outline-secondary">{el}</button>
    else
      el

  <form className="d-flex align-items-center justify-content-end" onSubmit={-> false}>
    <div className="d-flex align-items-center gap-2">
      {button shrink, <i onClick={shrink} className="fa fa-search-minus"/>}
      {
        if !small
          <input className="form-range" type="range" min="1" max="10" step="1" value={zoom} onChange={onChange}/>
      }
      {button grow, <i onClick={grow} className="fa fa-search-plus"/>}
    </div>
  </form>
