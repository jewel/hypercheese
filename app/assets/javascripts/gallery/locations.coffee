component 'Locations', ->
  [filter, setFilter] = React.useState ''
  [filteredLocations, setFilteredLocations] = React.useState []

  locations = Store.fetchLocations()
  places = Store.fetchPlaces()
  loading = locations == null || places == null

  useEffect ->
    if locations != null && places != null
      # Merge locations and places, adding a type field to distinguish them
      allLocations = []

      if locations
        locations.forEach (location) ->
          allLocations.push({...location, type: 'location'})

      if places
        places.forEach (place) ->
          allLocations.push({...place, type: 'place'})

      # Sort by item_count descending
      allLocations.sort (a, b) ->
        (b.item_count || 0) - (a.item_count || 0)

      if filter.trim() == ''
        setFilteredLocations allLocations
      else
        filtered = allLocations.filter (item) ->
          item.name.toLowerCase().includes(filter.toLowerCase())
        setFilteredLocations filtered
    ->
  , [filter, locations, places]

  onFilterChange = (e) ->
    setFilter e.target.value

  <div className="container-fluid">
    <div className="row">
      <div className="col-12">
        <div className="d-flex justify-content-between align-items-center">
          <h1>Locations</h1>
          <Writer>
            <Link href="/places/new" className="btn btn-primary">
              <i className="fa fa-plus"/> Create Place
            </Link>
          </Writer>
        </div>
        {
          <p className="text-muted">
            {filteredLocations.length} total locations and places
          </p>
        }
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
            placeholder="Filter locations and places by name..."
            value={filter}
            onChange={onFilterChange}
          />
        </div>
      </div>
      <div className="col-md-6">
        <p className="text-muted mt-2">
          Showing {filteredLocations.length} locations and places
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
                    <th>Location/Place</th>
                    <th className="text-end">Photo Count</th>
                    <th className="text-end">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {
                    filteredLocations.map (location) ->
                      name = location.name.replace(/ /g, "-")
                      searchUrl = "/search/in:#{encodeURIComponent(name)}"
                      icon = if location.type == 'place' then 'fa-map-marker' else 'fa-map-pin'
                      badgeClass = if location.type == 'place' then 'bg-success' else 'bg-primary'
                      <tr key={"#{location.type}-#{location.id}"}>
                        <td>
                          <Link href={searchUrl}>
                            <i className={"fa #{icon} me-2"}></i>
                            {location.name}
                          </Link>
                        </td>
                        <td className="text-end">
                          <Link href={searchUrl} className="text-decoration-none">
                            <span className={"badge #{badgeClass}"}>
                              {location.item_count?.toLocaleString() || 0}
                            </span>
                          </Link>
                        </td>
                        <td className="text-end">
                          {
                            if location.type == 'place'
                              <Writer>
                                <div className="btn-group btn-group-sm">
                                  <Link
                                    href={"/places/#{location.id}/edit"}
                                    className="btn btn-outline-secondary"
                                  >
                                    <i className="fa fa-edit"/> Edit
                                  </Link>
                                </div>
                              </Writer>
                          }
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
