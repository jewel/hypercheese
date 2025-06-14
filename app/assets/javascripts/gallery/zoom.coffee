component 'Zoom', ->
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

  <form className="d-flex align-items-center justify-content-end" onSubmit={-> false}>
    <div className="d-flex align-items-center gap-2">
      <button onClick={shrink} className="btn btn-outline-secondary d-flex d-md-none">
        <i className="fa fa-search-minus"/>
      </button>
      <div className="d-none d-md-flex">
        <i onClick={shrink} className="fa fa-search-minus"/>
        <input className="form-range" type="range" min="1" max="10" step="1" value={zoom} onChange={onChange}/>
        <i onClick={grow} className="fa fa-search-plus"/>
      </div>
      <button onClick={grow} className="btn btn-outline-secondary d-flex d-md-none">
        <i className="fa fa-search-plus"/>
      </button>
    </div>
  </form>
