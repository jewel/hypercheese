component 'PlaceMap', ({latitude, longitude, radius, onLocationChange, onRadiusChange}) ->
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

  # Initialize map only once
  useEffect ->
    unless mapInstanceRef.current
      defaultLat = latitude || 40.7706
      defaultLng = longitude || -111.8919

      mapInstanceRef.current = L.map(mapRef.current, {
        scrollWheelZoom: true
      }).setView([defaultLat, defaultLng], 12)

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors'
      }).addTo(mapInstanceRef.current)

      # Add click handler to place marker
      mapInstanceRef.current.on 'click', (e) ->
        lat = e.latlng.lat
        lng = e.latlng.lng
        onLocationChange lat, lng

    ->
      if mapInstanceRef.current
        mapInstanceRef.current.remove()
        mapInstanceRef.current = null
        markerRef.current = null
        circleRef.current = null
  , [] # Empty dependency array - only run once

  # Update marker and circle when props change
  useEffect ->
    return unless mapInstanceRef.current

    if latitude && longitude
      if markerRef.current
        markerRef.current.setLatLng([latitude, longitude])
      else
        markerRef.current = L.marker([latitude, longitude]).addTo(mapInstanceRef.current)

      if radius && radius > 0
        if circleRef.current
          circleRef.current.setLatLng([latitude, longitude])
          circleRef.current.setRadius(radius)
        else
          circleRef.current = L.circle([latitude, longitude], {
            radius: radius,
            color: '#3388ff',
            fillColor: '#3388ff',
            fillOpacity: 0.2,
            weight: 2
          }).addTo(mapInstanceRef.current)
    ->
  , [latitude, longitude, radius]

  <div className="leaflet-map" ref={mapRef} style={height: '400px', width: '100%', marginBottom: '10px'}/>
