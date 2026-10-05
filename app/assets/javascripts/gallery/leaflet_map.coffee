component 'LeafletMap', ({latitude, longitude, accuracy}) ->
  # Configure Leaflet icon paths to work with Rails asset pipeline
  delete L.Icon.Default.prototype._getIconUrl
  L.Icon.Default.mergeOptions
    iconRetinaUrl: LeafletAssets.iconRetinaUrl
    iconUrl: LeafletAssets.iconUrl
    shadowUrl: LeafletAssets.shadowUrl

  mapRef = React.useRef()
  markerRef = React.useRef()
  circleRef = React.useRef()
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

    if Number.isFinite(accuracy) && accuracy > 0
      if circleRef.current
        circleRef.current.setLatLng([lat, lon])
        circleRef.current.setRadius(accuracy)
      else
        circleRef.current = L.circle([lat, lon], {
          radius: accuracy,
          color: '#3388ff',
          fillColor: '#3388ff',
          fillOpacity: 0.2,
          weight: 2
        }).addTo(mapInstanceRef.current)
    else if circleRef.current
      circleRef.current.remove()
      circleRef.current = null

    ->
      if mapInstanceRef.current
        mapInstanceRef.current.remove()
        mapInstanceRef.current = null
        markerRef.current = null
        circleRef.current = null
  , [latitude, longitude, accuracy]

  return null unless Number.isFinite(latitude) && Number.isFinite(longitude)

  <div className="leaflet-map" ref={mapRef} style={height: '400px', width: '100%', marginBottom: '10px'}/>
