MAX_LAT = 85.0511287798

# Low to high density.  Index 0 is empty and 1 is the halo around each dot.
PALETTE = [
  [0, 0, 0, 0]
  [0, 0, 0, 140]
  [44, 123, 182, 255]
  [0, 166, 202, 255]
  [0, 204, 188, 255]
  [144, 235, 157, 255]
  [255, 255, 140, 255]
  [249, 208, 87, 255]
  [242, 158, 46, 255]
  [215, 25, 28, 255]
]

# ImageData is RGBA in memory; viewed as little-endian Uint32 that's ABGR
COLORS = new Uint32Array PALETTE.map ([r, g, b, a]) -> ((a << 24) | (b << 16) | (g << 8) | r) >>> 0
MAX_LEVEL = PALETTE.length - 3

cache =
  search: null
  data: null
  view: null

loadMapData = (search) ->
  query = new SearchQuery search
  searchKey = if Store.state.query == search then Store.state.searchKey else null
  params = $.param query: query.as_json(), search_key: searchKey || ''

  res = await fetch "/api/items/map?#{params}", credentials: 'same-origin'
  throw new Error "Server returned #{res.status}" unless res.ok
  buf = await res.arrayBuffer()

  [n, total] = new Uint32Array buf, 0, 2
  ids = new Uint32Array buf, 8, n
  lats = new Float32Array buf, 8 + 4 * n, n
  lons = new Float32Array buf, 8 + 8 * n, n
  codes = if n > 0 then new TextDecoder().decode(new Uint8Array buf, 8 + 12 * n).split "\n" else []

  # Normalized web mercator, 0..1 in both axes
  xs = new Float64Array n
  ys = new Float64Array n
  minLat = minLon = Infinity
  maxLat = maxLon = -Infinity
  for i in [0...n] by 1
    lat = lats[i]
    lon = lons[i]
    minLat = lat if lat < minLat
    maxLat = lat if lat > maxLat
    minLon = lon if lon < minLon
    maxLon = lon if lon > maxLon
    lat = Math.max -MAX_LAT, Math.min MAX_LAT, lat
    s = Math.sin lat * Math.PI / 180
    xs[i] = (lon + 180) / 360
    ys[i] = 0.5 - Math.log((1 + s) / (1 - s)) / (4 * Math.PI)

  bounds = if n > 0 then [[minLat, minLon], [maxLat, maxLon]] else null

  {n, total, ids, codes, xs, ys, bounds}

# Bins every point into a per-pixel grid on each redraw, then paints the grid
# with ImageData.  The grid doubles as the hover lookup.
PointLayer = L.Layer.extend
  initialize: (data) ->
    @_data = data
    @_width = 0
    @_height = 0

  onAdd: (map) ->
    @_canvas = L.DomUtil.create 'canvas', 'leaflet-layer'
    L.DomUtil.addClass @_canvas, if map._zoomAnimated then 'leaflet-zoom-animated' else 'leaflet-zoom-hide'
    @getPane().appendChild @_canvas
    @_ctx = @_canvas.getContext '2d'
    map.on 'move moveend zoomend resize viewreset', @_schedule, this
    map.on 'zoomanim', @_animateZoom, this if map._zoomAnimated
    @_redraw()

  onRemove: (map) ->
    map.off 'move moveend zoomend resize viewreset', @_schedule, this
    map.off 'zoomanim', @_animateZoom, this
    L.Util.cancelAnimFrame @_frame if @_frame
    @_frame = null
    L.DomUtil.remove @_canvas

  _schedule: ->
    return if @_frame
    @_frame = L.Util.requestAnimFrame =>
      @_frame = null
      @_redraw()

  _animateZoom: (e) ->
    scale = @_map.getZoomScale e.zoom
    offset = @_map._latLngBoundsToNewLayerBounds(@_bounds, e.zoom, e.center).min
    L.DomUtil.setTransform @_canvas, offset, scale

  _resize: (w, h) ->
    return if w == @_width && h == @_height
    @_width = w
    @_height = h
    @_canvas.width = w
    @_canvas.height = h
    @_canvas.style.width = "#{w}px"
    @_canvas.style.height = "#{h}px"
    @_counts = new Uint32Array w * h
    @_reps = new Int32Array w * h
    @_occupied = new Int32Array w * h
    @_levels = new Uint8Array w * h
    @_image = @_ctx.createImageData w, h
    @_pixels = new Uint32Array @_image.data.buffer

  _redraw: ->
    map = @_map
    return if !map || map._animatingZoom

    size = map.getSize()
    @_resize size.x, size.y
    W = @_width
    H = @_height
    return if W == 0 || H == 0

    L.DomUtil.setPosition @_canvas, map.containerPointToLayerPoint [0, 0]
    @_bounds = map.getBounds()

    origin = map.getPixelBounds().min
    scale = map.options.crs.scale map.getZoom()

    counts = @_counts
    reps = @_reps
    occupied = @_occupied
    levels = @_levels
    pixels = @_pixels
    {n, xs, ys} = @_data

    counts.fill 0
    levels.fill 0
    occupiedCount = 0

    # One pass per visible copy of the world
    for k in [Math.floor(origin.x / scale)..Math.floor((origin.x + W) / scale)]
      ox = origin.x - k * scale
      oy = origin.y
      for i in [0...n] by 1
        x = Math.floor xs[i] * scale - ox
        continue if x < 0 || x >= W
        y = Math.floor ys[i] * scale - oy
        continue if y < 0 || y >= H
        p = y * W + x
        if counts[p] == 0
          reps[p] = i
          occupied[occupiedCount++] = p
        counts[p]++

    for j in [0...occupiedCount] by 1
      p = occupied[j]
      level = 2 + Math.min MAX_LEVEL, 31 - Math.clz32 counts[p]
      x = p % W
      y = (p - x) / W
      for dy in [-2..2]
        yy = y + dy
        continue if yy < 0 || yy >= H
        for dx in [-2..2]
          xx = x + dx
          continue if xx < 0 || xx >= W
          v = if dx == -2 || dx == 2 || dy == -2 || dy == 2 then 1 else level
          q = yy * W + xx
          levels[q] = v if levels[q] < v

    for q in [0...W * H] by 1
      pixels[q] = COLORS[levels[q]]

    @_ctx.putImageData @_image, 0, 0

  # Nearest occupied pixel to a container point, within `radius` pixels
  hitTest: (point, radius = 6) ->
    return null unless @_counts
    W = @_width
    H = @_height
    cx = Math.floor point.x
    cy = Math.floor point.y
    best = -1
    bestDist = Infinity
    for dy in [-radius..radius]
      y = cy + dy
      continue if y < 0 || y >= H
      for dx in [-radius..radius]
        x = cx + dx
        continue if x < 0 || x >= W
        p = y * W + x
        continue if @_counts[p] == 0
        dist = dx * dx + dy * dy
        if dist < bestDist
          bestDist = dist
          best = p
    return null if best < 0
    x = best % W
    index: @_reps[best]
    count: @_counts[best]
    x: x
    y: (best - x) / W

component 'SearchMap', ({search}) ->
  [data, setData] = useState -> if cache.search == search then cache.data else null
  [error, setError] = useState null
  [hover, setHover] = useState null
  containerRef = useRef()
  hoverRef = useRef null
  touchRef = useRef false

  ready = Store.state.tagsLoaded

  useEffect ->
    return unless ready && !data
    cancelled = false
    loadMapData(search)
      .then (d) ->
        return if cancelled
        cache.search = search
        cache.data = d
        cache.view = null
        setData d
      .catch (e) ->
        setError e.message unless cancelled
    -> cancelled = true
  , [search, ready, data]

  useEffect ->
    return unless data
    container = containerRef.current

    map = L.map container
    if cache.view
      map.setView cache.view.center, cache.view.zoom
    else if data.bounds
      map.fitBounds data.bounds, padding: [20, 20], maxZoom: 16
    else
      map.setView [20, 0], 2

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors'
      maxZoom: 19
    }).addTo map

    layer = new PointLayer data
    layer.addTo map

    updateHover = (h) ->
      prev = hoverRef.current
      return if !prev && !h
      return if prev && h && prev.index == h.index && prev.x == h.x && prev.y == h.y && prev.touch == h.touch
      hoverRef.current = h
      container.classList.toggle 'supermap-hovering', !!h
      setHover h

    openItem = (index) ->
      Store.navigate "/search/#{encodeURI search}/#{data.ids[index]}"

    onPointerDown = (e) ->
      touchRef.current = e.pointerType == 'touch'

    map.on 'mousemove', (e) ->
      return if touchRef.current
      updateHover layer.hitTest e.containerPoint

    map.on 'mouseout', ->
      updateHover null unless touchRef.current

    # On touch the first tap previews and a second tap opens
    map.on 'click', (e) ->
      hit = layer.hitTest e.containerPoint, if touchRef.current then 12 else 6
      return updateHover null unless hit
      if touchRef.current && hoverRef.current?.index != hit.index
        return updateHover {hit..., touch: true}
      openItem hit.index

    map.on 'movestart zoomstart', ->
      updateHover null

    map.on 'moveend', ->
      cache.view = center: map.getCenter(), zoom: map.getZoom()

    container.addEventListener 'pointerdown', onPointerDown, true

    ->
      container.removeEventListener 'pointerdown', onPointerDown, true
      map.remove()
      hoverRef.current = null
  , [data]

  onPreviewClick = ->
    Store.navigate "/search/#{encodeURI search}/#{data.ids[hover.index]}" if hover

  status = if error
    "Failed to load: #{error}"
  else if !data
    "Loading…"
  else
    "#{data.n.toLocaleString()} of #{data.total.toLocaleString()} have a location"

  <div className="supermap">
    <div className="supermap-header bg-light">
      <Link className="btn btn-outline-secondary" title="Back to results" href={"/search/#{encodeURI search}"}>
        <i className="fa fa-arrow-left fa-fw"/>
      </Link>
      <span className="supermap-query">
        <i className="fa fa-search fa-fw"/> {search}
      </span>
      <span className="badge bg-secondary">{status}</span>
    </div>
    <div className="supermap-body">
      <div className="supermap-map" ref={containerRef}/>
      {
        if hover
          classes = ['supermap-preview']
          classes.push 'below' if hover.y < 190
          classes.push 'touch' if hover.touch
          <div className={classes.join ' '} style={left: hover.x, top: hover.y} onClick={onPreviewClick}>
            <img src={Store.resizedURL 'square', data.ids[hover.index], data.codes[hover.index]}/>
            {
              if hover.count > 1
                <div>+{(hover.count - 1).toLocaleString()} more here</div>
            }
          </div>
      }
    </div>
  </div>
