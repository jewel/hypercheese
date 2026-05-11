component 'LeafletMap', ({latitude, longitude}) ->
  # Configure Leaflet icon paths to work with Rails asset pipeline
  delete L.Icon.Default.prototype._getIconUrl
  L.Icon.Default.mergeOptions
    iconRetinaUrl: LeafletAssets.iconRetinaUrl
    iconUrl: LeafletAssets.iconUrl
    shadowUrl: LeafletAssets.shadowUrl

  mapRef = React.useRef()
  markerRef = React.useRef()
  mapInstanceRef = React.useRef()

  useEffect ->
    return unless Number.isFinite(latitude) && Number.isFinite(longitude)
    lat = latitude
    lon = longitude

    unless mapInstanceRef.current
      mapInstanceRef.current = L.map(mapRef.current, {
        scrollWheelZoom: false
      }).setView([lat, lon], 12)
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors'
      }).addTo(mapInstanceRef.current)

    if markerRef.current
      markerRef.current.setLatLng([lat, lon])
    else
      markerRef.current = L.marker([lat, lon]).addTo(mapInstanceRef.current)

    ->
      if mapInstanceRef.current
        mapInstanceRef.current.remove()
        mapInstanceRef.current = null
        markerRef.current = null
  , [latitude, longitude]

  return null unless Number.isFinite(latitude) && Number.isFinite(longitude)

  <div className="leaflet-map" ref={mapRef} style={height: '400px', width: '100%', marginBottom: '10px'}/>
