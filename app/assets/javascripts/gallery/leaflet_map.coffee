component 'LeafletMap', ({exif}) ->
  # Configure Leaflet icon paths to work with Rails asset pipeline
  delete L.Icon.Default.prototype._getIconUrl
  L.Icon.Default.mergeOptions
    iconRetinaUrl: LeafletAssets.iconRetinaUrl
    iconUrl: LeafletAssets.iconUrl
    shadowUrl: LeafletAssets.shadowUrl

  mapRef = React.useRef()
  markerRef = React.useRef()
  mapInstanceRef = React.useRef()

  r = (frac) ->
    parts = frac.split "/"
    n = parseInt parts[0], 10
    d = parseInt parts[1], 10
    n / d

  coord = (input) ->
    c = r(input[0]) + r(input[1])/60 + r(input[2])/3600
    c.toFixed 7

  useEffect ->
    return unless exif?.gps_latitude && exif?.gps_longitude

    lat = coord exif.gps_latitude
    lat *= -1 if exif.gps_latitude_ref == "S"
    lon = coord exif.gps_longitude
    lon *= -1 if exif.gps_longitude_ref == "W"

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
  , [exif]

  return null unless exif?.gps_latitude && exif?.gps_longitude

  <div className="leaflet-map" ref={mapRef} style={height: '400px', width: '100%', marginBottom: '10px'}/>
