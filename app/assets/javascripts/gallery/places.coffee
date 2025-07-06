component 'Places', ->
  [places, setPlaces] = React.useState []
  [loading, setLoading] = React.useState true
  [error, setError] = React.useState null
  [showCreateForm, setShowCreateForm] = React.useState false
  [editingPlace, setEditingPlace] = React.useState null

  loadPlaces = ->
    setLoading true
    setError null
    fetch '/api/places'
      .then (response) ->
        if response.ok
          response.json()
        else
          throw new Error 'Failed to load places'
      .then (data) ->
        setPlaces data
        setLoading false
      .catch (err) ->
        setError err.message
        setLoading false

  React.useEffect ->
    loadPlaces()
  , []

  onCreatePlace = (newPlace) ->
    setPlaces [...places, newPlace]
    setShowCreateForm false

  onUpdatePlace = (updatedPlace) ->
    setPlaces places.map (p) ->
      if p.id == updatedPlace.id then updatedPlace else p
    setEditingPlace null

  onDeletePlace = (placeId) ->
    if confirm 'Are you sure you want to delete this place?'
      fetch "/api/places/#{placeId}",
        method: 'DELETE'
        headers:
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      .then (response) ->
        if response.ok
          setPlaces places.filter (p) -> p.id != placeId
        else
          throw new Error 'Failed to delete place'
      .catch (err) ->
        alert "Error deleting place: #{err.message}"

  if loading
    return <div className="text-center p-4">Loading places...</div>

  if error
    return <div className="alert alert-danger">Error: {error}</div>

  <div className="container mt-4">
    <div className="d-flex justify-content-between align-items-center mb-4">
      <h2>Places</h2>
      <button 
        className="btn btn-primary" 
        onClick={() => setShowCreateForm(true)}
      >
        <i className="fa fa-plus"/> Create Place
      </button>
    </div>

    {
      if showCreateForm
        <PlaceForm 
          onSubmit={onCreatePlace} 
          onCancel={() => setShowCreateForm(false)}
        />
    }

    {
      if editingPlace
        <PlaceForm 
          place={editingPlace}
          onSubmit={onUpdatePlace} 
          onCancel={() => setEditingPlace(null)}
        />
    }

    <div className="row">
      {
        places.map (place) ->
          <div key={place.id} className="col-md-6 col-lg-4 mb-4">
            <div className="card">
              <div className="card-body">
                <h5 className="card-title">{place.name}</h5>
                <p className="card-text">
                  <small className="text-muted">
                    <i className="fa fa-map-marker"/> {place.latitude}, {place.longitude}
                  </small>
                  <br/>
                  <small className="text-muted">
                    <i className="fa fa-circle-o"/> {place.radius}m radius
                  </small>
                  <br/>
                  <small className="text-muted">
                    <i className="fa fa-user"/> Created by {place.creator_name}
                  </small>
                  <br/>
                  <small className="text-muted">
                    <i className="fa fa-photo"/> {place.item_count} items
                  </small>
                </p>
                <div className="btn-group btn-group-sm">
                  <button 
                    className="btn btn-outline-secondary"
                    onClick={() => setEditingPlace(place)}
                  >
                    <i className="fa fa-edit"/> Edit
                  </button>
                  <button 
                    className="btn btn-outline-danger"
                    onClick={() => onDeletePlace(place.id)}
                  >
                    <i className="fa fa-trash"/> Delete
                  </button>
                </div>
              </div>
            </div>
          </div>
      }
    </div>

    {
      if places.length == 0
        <div className="text-center p-5">
          <i className="fa fa-map-marker fa-3x text-muted"/>
          <p className="mt-3 text-muted">No places created yet.</p>
        </div>
    }
  </div>

component 'PlaceForm', ({place, onSubmit, onCancel}) ->
  [name, setName] = React.useState place?.name || ''
  [latitude, setLatitude] = React.useState place?.latitude || ''
  [longitude, setLongitude] = React.useState place?.longitude || ''
  [radius, setRadius] = React.useState place?.radius || ''
  [submitting, setSubmitting] = React.useState false

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
      onSubmit(data)
      setSubmitting false
    .catch (err) ->
      alert "Error saving place: #{err.message}"
      setSubmitting false

  <div className="card mb-4">
    <div className="card-header">
      <h5>{if place then 'Edit Place' else 'Create New Place'}</h5>
    </div>
    <div className="card-body">
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
        <div className="row">
          <div className="col-md-6">
            <div className="mb-3">
              <label className="form-label">Latitude</label>
              <input
                type="number"
                step="any"
                className="form-control"
                value={latitude}
                onChange={(e) => setLatitude(e.target.value)}
                required
              />
            </div>
          </div>
          <div className="col-md-6">
            <div className="mb-3">
              <label className="form-label">Longitude</label>
              <input
                type="number"
                step="any"
                className="form-control"
                value={longitude}
                onChange={(e) => setLongitude(e.target.value)}
                required
              />
            </div>
          </div>
        </div>
        <div className="mb-3">
          <label className="form-label">Radius (meters)</label>
          <input
            type="number"
            step="any"
            className="form-control"
            value={radius}
            onChange={(e) => setRadius(e.target.value)}
            required
          />
        </div>
        <div className="d-flex gap-2">
          <button type="submit" className="btn btn-primary" disabled={submitting}>
            {if submitting then 'Saving...' else (if place then 'Update Place' else 'Create Place')}
          </button>
          <button type="button" className="btn btn-secondary" onClick={onCancel}>
            Cancel
          </button>
        </div>
      </form>
    </div>
  </div>