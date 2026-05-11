component 'MapPage', ->
  [latitude, setLatitude] = React.useState null
  [longitude, setLongitude] = React.useState null
  [radius, setRadius] = React.useState 1000

  onLocationChange = (lat, lng) ->
    setLatitude lat
    setLongitude lng

  onRadiusChange = (e) ->
    meters = parseFloat e.target.value
    setRadius if Number.isFinite(meters) then meters else 0

  onSearch = (e) ->
    e.preventDefault()
    return unless Number.isFinite(latitude) && Number.isFinite(longitude) && radius > 0

    loc = "#{latitude.toFixed(6)},#{longitude.toFixed(6)}"
    meters = radius.toString()
    searchString = "near:#{loc} radius:#{meters}"
    Store.search searchString, true
    Store.navigate '/search/' + encodeURI(searchString)

  searchDisabled = !Number.isFinite(latitude) || !Number.isFinite(longitude) || radius <= 0

  <div className="container-fluid">
    <div className="row">
      <div className="col-12">
        <h1>Map</h1>
        <p className="text-muted">Tap the map to pick a location, set a radius in meters, then search.</p>
      </div>
    </div>
    <form onSubmit={onSearch}>
      <div className="row">
        <div className="col-12">
          <PlaceMap
            latitude={latitude}
            longitude={longitude}
            radius={radius}
            onLocationChange={onLocationChange}
            onRadiusChange={onRadiusChange}
          />
        </div>
      </div>
      <div className="row g-2 align-items-end">
        <div className="col-sm-6 col-md-4">
          <label className="form-label">Radius (meters)</label>
          <input
            type="number"
            step="any"
            min="1"
            className="form-control"
            value={radius}
            onChange={onRadiusChange}
            required
          />
        </div>
        <div className="col-sm-6 col-md-4">
          <button type="submit" className="btn btn-primary" disabled={searchDisabled}>
            <i className="fa fa-search"/> Search
          </button>
        </div>
      </div>
    </form>
  </div>
