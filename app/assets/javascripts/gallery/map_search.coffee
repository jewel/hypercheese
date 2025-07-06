component 'MapSearch', ->
  [items, setItems] = useState([])
  [selectedItem, setSelectedItem] = useState(null)
  [hoveredItem, setHoveredItem] = useState(null)
  [isLoading, setIsLoading] = useState(false)
  mapRef = useRef()
  mapInstanceRef = useRef()
  markersRef = useRef({})
  
  # Configure Leaflet icon paths
  useEffect ->
    return unless L?
    delete L.Icon.Default.prototype._getIconUrl
    L.Icon.Default.mergeOptions
      iconRetinaUrl: '/assets/leaflet/marker-icon-2x.png'
      iconUrl: '/assets/leaflet/marker-icon.png'
      shadowUrl: '/assets/leaflet/marker-shadow.png'
  , []

  # Initialize map
  useEffect ->
    return unless mapRef.current && !mapInstanceRef.current

    mapInstanceRef.current = L.map(mapRef.current, {
      scrollWheelZoom: true,
      touchZoom: true
    }).setView([40.7128, -74.0060], 10) # Default to NYC

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors'
    }).addTo(mapInstanceRef.current)

    # Add event listeners for map movements
    mapInstanceRef.current.on 'moveend', loadItemsInBounds
    mapInstanceRef.current.on 'zoomend', loadItemsInBounds

    # Load initial items
    loadItemsInBounds()

    # Cleanup function
    ->
      if mapInstanceRef.current
        mapInstanceRef.current.remove()
        mapInstanceRef.current = null
        markersRef.current = {}
  , []

  # Load items within current map bounds
  loadItemsInBounds = ->
    return unless mapInstanceRef.current
    
    setIsLoading(true)
    bounds = mapInstanceRef.current.getBounds()
    
    params = new URLSearchParams({
      north: bounds.getNorth(),
      south: bounds.getSouth(),
      east: bounds.getEast(),
      west: bounds.getWest()
    })
    
    fetch("/api/items/map_search?" + params.toString())
      .then((response) -> response.json())
      .then((data) -> 
        setItems(data)
        setIsLoading(false)
        updateMarkers(data)
      )
      .catch((error) -> 
        console.error('Error loading items:', error)
        setIsLoading(false)
      )

  # Update markers on map
  updateMarkers = (newItems) ->
    return unless mapInstanceRef.current
    
    # Clear existing markers
    Object.values(markersRef.current).forEach((marker) -> 
      mapInstanceRef.current.removeLayer(marker)
    )
    markersRef.current = {}
    
    # Add new markers
    newItems.forEach((item) ->
      return unless item.latitude && item.longitude
      
      # Create custom icon with thumbnail
      iconHtml = """
        <div class="map-photo-marker" style="
          width: 40px; 
          height: 40px; 
          border-radius: 50%; 
          overflow: hidden; 
          border: 2px solid #fff; 
          box-shadow: 0 2px 4px rgba(0,0,0,0.3);
          cursor: pointer;
        ">
          <img src="/data/resized/160/#{item.id}-#{item.code}.jpg" 
               style="width: 100%; height: 100%; object-fit: cover;"
               alt="Photo thumbnail" />
        </div>
      """
      
      customIcon = L.divIcon({
        html: iconHtml,
        iconSize: [40, 40],
        iconAnchor: [20, 20],
        popupAnchor: [0, -20],
        className: 'custom-map-marker'
      })
      
      marker = L.marker([item.latitude, item.longitude], {
        icon: customIcon
      }).addTo(mapInstanceRef.current)
      
      # Add click handler
      marker.on('click', -> 
        setSelectedItem(item)
      )
      
      # Add hover handlers
      marker.on('mouseover', -> 
        setHoveredItem(item)
      )
      
      marker.on('mouseout', -> 
        setHoveredItem(null)
      )
      
      markersRef.current[item.id] = marker
    )

  # Handle photo click to navigate to item page
  onPhotoClick = (item) ->
    Store.navigate("/items/#{item.id}")

  # Render large photo overlay
  renderPhotoOverlay = ->
    return null unless hoveredItem || selectedItem
    
    item = selectedItem || hoveredItem
    
    <div className="photo-overlay" style={{
      position: 'fixed',
      top: '50%',
      left: '50%',
      transform: 'translate(-50%, -50%)',
      zIndex: 1000,
      backgroundColor: 'white',
      padding: '10px',
      borderRadius: '8px',
      boxShadow: '0 4px 12px rgba(0,0,0,0.5)',
      maxWidth: '80vw',
      maxHeight: '80vh',
      cursor: if selectedItem then 'pointer' else 'default'
    }} onClick={if selectedItem then (-> onPhotoClick(item)) else null}>
      <img 
        src="/data/resized/800/#{item.id}-#{item.code}.jpg"
        alt="Photo"
        style={{
          maxWidth: '100%',
          maxHeight: '70vh',
          objectFit: 'contain'
        }}
      />
      <div style={{
        marginTop: '10px',
        textAlign: 'center',
        fontSize: '14px',
        color: '#666'
      }}>
        {if item.taken then new Date(item.taken).toLocaleDateString() else 'Unknown date'}
        {if selectedItem then ' - Click to view full photo' else ''}
      </div>
    </div>

  # Render backdrop for overlay
  renderBackdrop = ->
    return null unless selectedItem
    
    <div 
      className="photo-overlay-backdrop" 
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(0,0,0,0.5)',
        zIndex: 999
      }}
      onClick={-> setSelectedItem(null)}
    />

  <div className="map-search-container" style={{position: 'relative', height: '100vh'}}>
    <div 
      className="map-container" 
      ref={mapRef} 
      style={{
        height: '100%',
        width: '100%'
      }}
    />
    
    {if isLoading
      <div className="loading-indicator" style={{
        position: 'absolute',
        top: '10px',
        right: '10px',
        backgroundColor: 'rgba(255,255,255,0.9)',
        padding: '8px 12px',
        borderRadius: '4px',
        zIndex: 1000
      }}>
        Loading photos...
      </div>
    }
    
    <div className="map-info" style={{
      position: 'absolute',
      bottom: '10px',
      left: '10px',
      backgroundColor: 'rgba(255,255,255,0.9)',
      padding: '8px 12px',
      borderRadius: '4px',
      zIndex: 1000,
      fontSize: '14px'
    }}>
      {items.length} photos found
    </div>
    
    {renderBackdrop()}
    {renderPhotoOverlay()}
  </div>