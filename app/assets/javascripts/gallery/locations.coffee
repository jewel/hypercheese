component 'Locations', ->
  [locations, setLocations] = React.useState []
  [loading, setLoading] = React.useState true
  [filter, setFilter] = React.useState ''
  [filteredLocations, setFilteredLocations] = React.useState []

  useEffect ->
    fetchLocations()
    ->
  , []

  fetchLocations = ->
    setLoading true
    fetch('/api/locations')
      .then (response) -> response.json()
      .then (data) ->
        setLocations data
        setFilteredLocations data
        setLoading false
      .catch (error) ->
        console.error 'Error fetching locations:', error
        setLoading false

  useEffect ->
    if filter.trim() == ''
      setFilteredLocations locations
    else
      filtered = locations.filter (location) ->
        location.name.toLowerCase().includes(filter.toLowerCase())
      setFilteredLocations filtered
    ->
  , [locations, filter]

  onFilterChange = (e) ->
    setFilter e.target.value

  <div className="container-fluid">
    <div className="row">
      <div className="col-12">
        <h1>Locations</h1>
        <p className="text-muted">
          {locations.length} total locations with photos
        </p>
      </div>
    </div>

    <div className="row mb-3">
      <div className="col-md-6">
        <div className="input-group">
          <span className="input-group-text">
            <i className="fa fa-search"></i>
          </span>
          <input
            type="text"
            className="form-control"
            placeholder="Filter locations by name..."
            value={filter}
            onChange={onFilterChange}
          />
        </div>
      </div>
      <div className="col-md-6">
        <p className="text-muted mt-2">
          Showing {filteredLocations.length} locations
        </p>
      </div>
    </div>

    {
      if loading
        <div className="text-center">
          <div className="spinner-border" role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
        </div>
      else
        <div className="row">
          <div className="col-12">
            <div className="table-responsive">
              <table className="table table-striped">
                <thead>
                  <tr>
                    <th>Location</th>
                    <th className="text-end">Photo Count</th>
                  </tr>
                </thead>
                <tbody>
                  {
                    filteredLocations.map (location) ->
                      searchUrl = "/search/in:#{encodeURIComponent(location.name)}"
                      <tr key={location.id}>
                        <td>
                          <Link href={searchUrl}>
                            {location.name}
                          </Link>
                        </td>
                        <td className="text-end">
                          <Link href={searchUrl} className="text-decoration-none">
                            <span className="badge bg-primary">
                              {location.photo_count?.toLocaleString() || 0}
                            </span>
                          </Link>
                        </td>
                      </tr>
                  }
                </tbody>
              </table>
            </div>
          </div>
        </div>
    }
  </div>
