component 'PlaceForm', ({place, onSubmit, onCancel}) ->
  [name, setName] = React.useState place?.name || ''
  [latitude, setLatitude] = React.useState place?.latitude || ''
  [longitude, setLongitude] = React.useState place?.longitude || ''
  [radius, setRadius] = React.useState place?.radius || 20
  [submitting, setSubmitting] = React.useState false

  handleLocationChange = (lat, lng) ->
    setLatitude lat
    setLongitude lng

  handleRadiusChange = (e) ->
    newRadius = parseFloat(e.target.value) || 0
    setRadius newRadius

  handleSubmit = (e) ->
    e.preventDefault()
    setSubmitting true

    data = {
      name: name,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      radius: parseFloat(radius)
    }

    method = if place then 'PUT' else 'POST'
    url = if place then "/api/places/#{place.id}" else '/api/places'

    fetch url,
      method: method
      headers:
        'Content-Type': 'application/json'
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      body: JSON.stringify(place: data)
    .then (response) ->
      if response.ok
        response.json()
      else
        throw new Error 'Failed to save place'
    .then (data) ->
      # Refresh places from store after saving
      Store.state.places = null
      Store.fetchPlaces()
      # Navigate back to locations list
      Store.navigate '/locations'
      setSubmitting false
    .catch (err) ->
      alert "Error saving place: #{err.message}"
      setSubmitting false

  <div className="container-fluid">
    <div className="row">
      <div className="col-12">
        <h1>{if place then 'Edit Place' else 'Create New Place'}</h1>
      </div>
    </div>
    <div className="row">
      <div className="col-12">
        <form onSubmit={handleSubmit}>
          <div className="mb-3">
            <label className="form-label">Name</label>
            <input
              type="text"
              className="form-control"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </div>

          <div className="mb-3">
            <label className="form-label">Location</label>
            <p className="text-muted small">Click on the map to set the location</p>
            <PlaceMap
              latitude={parseFloat(latitude)}
              longitude={parseFloat(longitude)}
              radius={parseFloat(radius)}
              onLocationChange={handleLocationChange}
              onRadiusChange={handleRadiusChange}
            />
          </div>

          <div className="mb-3">
            <label className="form-label">Radius (meters)</label>
            <input
              type="number"
              step="any"
              className="form-control"
              value={radius}
              onChange={handleRadiusChange}
              required
            />
          </div>

          <div className="d-flex gap-2">
            <button type="submit" className="btn btn-primary" disabled={submitting}>
              {if submitting then 'Saving...' else (if place then 'Update Place' else 'Create Place')}
            </button>
            <Link href="/locations" className="btn btn-secondary">
              Cancel
            </Link>
          </div>
        </form>
      </div>
    </div>
  </div>
