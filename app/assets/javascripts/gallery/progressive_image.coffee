component 'ProgressiveImage', ({item, width, height, className, style}) ->
  [zoomLevel, setZoomLevel] = useState 1
  [isPinching, setIsPinching] = useState false
  [tiles, setTiles] = useState {}
  [baseImageLoaded, setBaseImageLoaded] = useState false
  [currentResolution, setCurrentResolution] = useState 'square'
  [lastTouchDistance, setLastTouchDistance] = useState 0
  [transformOrigin, setTransformOrigin] = useState '50% 50%'
  [imageTransform, setImageTransform] = useState ''
  
  containerRef = useRef null
  imageRef = useRef null
  
  # Detect high-resolution displays
  isHighDPI = window.devicePixelRatio > 1
  
  # Calculate appropriate base resolution based on display size and DPI
  getBaseResolution = ->
    if width > 800 || isHighDPI
      'large'
    else if width > 400
      'large'
    else
      'square'
  
  # Calculate tile size based on zoom level and container size
  getTileSize = ->
    baseSize = 256
    if zoomLevel > 2
      baseSize = 512
    else if zoomLevel > 4
      baseSize = 1024
    baseSize
  
  # Calculate which tiles need to be loaded
  calculateVisibleTiles = (zoom, centerX = 0.5, centerY = 0.5) ->
    return {} unless item?.id
    
    tileSize = getTileSize()
    
    # Calculate how many tiles we need based on zoom level
    tilesX = Math.ceil(width * zoom / tileSize)
    tilesY = Math.ceil(height * zoom / tileSize)
    
    # Calculate the center tile
    centerTileX = Math.floor(centerX * tilesX)
    centerTileY = Math.floor(centerY * tilesY)
    
    visibleTiles = {}
    
    # Load tiles in a spiral pattern from center
    for x in [Math.max(0, centerTileX - 1)..Math.min(tilesX - 1, centerTileX + 1)]
      for y in [Math.max(0, centerTileY - 1)..Math.min(tilesY - 1, centerTileY + 1)]
        tileKey = "#{x}_#{y}_#{zoom}_#{tileSize}"
        visibleTiles[tileKey] = 
          x: x
          y: y
          zoom: zoom
          size: tileSize
          url: getTileURL(x, y, zoom, tileSize)
    
    visibleTiles
  
  # Generate tile URL - this would need to be implemented on the server side
  getTileURL = (tileX, tileY, zoom, tileSize) ->
    return null unless item?.id
    
    # Use the new tile endpoint
    "/data/tiles/#{item.id}/#{zoom}/#{tileX}/#{tileY}/#{tileSize}.jpg"
  
  # Handle touch events for pinch-to-zoom
  handleTouchStart = (e) ->
    if e.touches.length == 2
      setIsPinching true
      touch1 = e.touches[0]
      touch2 = e.touches[1]
      distance = Math.sqrt(
        Math.pow(touch2.clientX - touch1.clientX, 2) +
        Math.pow(touch2.clientY - touch1.clientY, 2)
      )
      setLastTouchDistance distance
      
      # Calculate transform origin based on pinch center
      rect = e.currentTarget.getBoundingClientRect()
      centerX = (touch1.clientX + touch2.clientX) / 2 - rect.left
      centerY = (touch1.clientY + touch2.clientY) / 2 - rect.top
      originX = (centerX / rect.width) * 100
      originY = (centerY / rect.height) * 100
      setTransformOrigin "#{originX}% #{originY}%"
  
  handleTouchMove = (e) ->
    if isPinching && e.touches.length == 2
      e.preventDefault()
      
      touch1 = e.touches[0]
      touch2 = e.touches[1]
      distance = Math.sqrt(
        Math.pow(touch2.clientX - touch1.clientX, 2) +
        Math.pow(touch2.clientY - touch1.clientY, 2)
      )
      
      if lastTouchDistance > 0
        newZoom = zoomLevel * (distance / lastTouchDistance)
        newZoom = Math.max(1, Math.min(10, newZoom))
        setZoomLevel newZoom
        
        # Update image transform
        setImageTransform "scale(#{newZoom})"
      
      setLastTouchDistance distance
  
  handleTouchEnd = (e) ->
    if e.touches.length < 2
      setIsPinching false
      setLastTouchDistance 0
  
  # Handle wheel zoom for desktop
  handleWheel = (e) ->
    if e.ctrlKey || e.metaKey
      e.preventDefault()
      
      delta = e.deltaY
      zoomChange = delta > 0 ? 0.9 : 1.1
      newZoom = zoomLevel * zoomChange
      newZoom = Math.max(1, Math.min(10, newZoom))
      setZoomLevel newZoom
      
      # Calculate transform origin based on mouse position
      rect = e.currentTarget.getBoundingClientRect()
      originX = ((e.clientX - rect.left) / rect.width) * 100
      originY = ((e.clientY - rect.top) / rect.height) * 100
      setTransformOrigin "#{originX}% #{originY}%"
      
      # Update image transform
      setImageTransform "scale(#{newZoom})"
  
  # Load tiles when zoom level changes
  useEffect ->
    if zoomLevel > 1.2 || isHighDPI
      visibleTiles = calculateVisibleTiles(zoomLevel)
      setTiles visibleTiles
      
      # Update resolution based on zoom
      newResolution = if zoomLevel > 3 then 'exploded' else if zoomLevel > 1.5 then 'large' else 'square'
      if newResolution != currentResolution
        setCurrentResolution newResolution
  , [zoomLevel, width, height, item?.id]
  
  # Load base resolution based on display characteristics
  useEffect ->
    baseRes = getBaseResolution()
    setCurrentResolution baseRes
  , [width, height, isHighDPI]
  
  # Base image URL
  baseImageURL = if item?.id
    Store.resizedURL currentResolution, item
  else
    "/images/loading.png"
  
  combinedStyle = Object.assign({}, style, {
    width: "#{width}px"
    height: "#{height}px"
    position: 'relative'
    overflow: 'hidden'
    cursor: if zoomLevel > 1 then 'grab' else 'auto'
  })
  
  imageStyle = 
    width: '100%'
    height: '100%'
    objectFit: 'cover'
    transform: imageTransform
    transformOrigin: transformOrigin
    transition: if isPinching then 'none' else 'transform 0.2s ease-out'
  
  <div 
    ref={containerRef}
    className={className}
    style={combinedStyle}
    onTouchStart={handleTouchStart}
    onTouchMove={handleTouchMove}
    onTouchEnd={handleTouchEnd}
    onWheel={handleWheel}
  >
    <img
      ref={imageRef}
      src={baseImageURL}
      style={imageStyle}
      onLoad={-> setBaseImageLoaded true}
      onError={-> setBaseImageLoaded false}
    />
    
    {# Overlay tiles for high-resolution areas when zoomed #}
    {
      if zoomLevel > 1.2 && Object.keys(tiles).length > 0
        Object.keys(tiles).map (tileKey) ->
          tile = tiles[tileKey]
          tileStyle = 
            position: 'absolute'
            left: "#{(tile.x / (width * zoomLevel / tile.size)) * 100}%"
            top: "#{(tile.y / (height * zoomLevel / tile.size)) * 100}%"
            width: "#{(tile.size / (width * zoomLevel)) * 100}%"
            height: "#{(tile.size / (height * zoomLevel)) * 100}%"
            opacity: 0.8
            pointerEvents: 'none'
            
          <img
            key={tileKey}
            src={tile.url}
            style={tileStyle}
            onLoad={-> console.log "Tile loaded: #{tileKey}"}
          />
    }
    
    {# Zoom indicator #}
    {
      if zoomLevel > 1.1
        <div style={{
          position: 'absolute'
          top: '10px'
          right: '10px'
          background: 'rgba(0,0,0,0.7)'
          color: 'white'
          padding: '4px 8px'
          borderRadius: '4px'
          fontSize: '12px'
          pointerEvents: 'none'
        }}>
          {Math.round(zoomLevel * 100)}%
        </div>
    }
  </div>