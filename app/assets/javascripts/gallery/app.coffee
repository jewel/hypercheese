parseUrl = ->
  path = window.location.pathname
  if path == '' || path == '/'
    return
      page: 'home'

  parts = path.split('/')
  if parts.length == 1 || parts[0] != ''
    console.warn "Invalid URL: #{path}"
    return
      page: 'home'

  if parts[1] == 'items'
    return
      page: 'item'
      itemId: Math.round(parts[2])

  if parts[1] == 'tags' && parts[2]
    return
      page: 'tag'
      tagId: parts[2]

  if parts[1] == 'tags'
    return
      page: 'tags'

  if parts[1] == 'upload'
    return
      page: 'upload'

  if parts[1] == 'search'
    str = decodeURI parts[2]
    Store.search str
    return
      page: 'search'
      search: str

  console.warn "Invalid URL: #{path}"
  return
    page: 'home'

component 'GalleryApp', withErrorBoundary ->
  # Break down state into separate variables
  [page, setPage] = React.useState -> parseUrl().page
  [itemId, setItemId] = React.useState -> parseUrl().itemId
  [tagId, setTagId] = React.useState -> parseUrl().tagId
  [search, setSearch] = React.useState -> parseUrl().search || ''
  [update, setUpdate] = React.useState 0
  [draggingCount, setDraggingCount] = React.useState 0
  uploaderRef = React.useRef null

  onGlobalDragEnter = (e) ->
    e.preventDefault()
    e.stopPropagation()
    # Only show upload dialog if dragging files
    if e.dataTransfer.types.includes('Files')
      setDraggingCount (prev) -> prev + 1

  onGlobalDragLeave = (e) ->
    e.preventDefault()
    e.stopPropagation()
    setDraggingCount (prev) -> prev - 1

  onGlobalDragOver = (e) ->
    e.preventDefault()
    e.stopPropagation()

  onGlobalDrop = (e) ->
    e.preventDefault()
    e.stopPropagation()
    setDraggingCount 0

    if e.dataTransfer.files.length > 0
      # Navigate to upload page if not already there
      if page != 'upload'
        Store.navigate '/upload'
      # Queue the files for upload
      uploaderRef.current?.addFiles e.dataTransfer.files

  onKeyUp = (e) ->
    if e.keyCode == 27
      while lastOpened = Store.state.openStack.pop()
        if lastOpened == 'item' && page == 'item'
          Store.navigateBack()
          break
        if lastOpened == 'select' && Store.state.selectionCount > 0 || Store.state.selectMode
          Store.state.selectMode = false
          Store.clearSelection()
          break

  onTouchStart = ->
    # No way to flip-flop on this at the moment, since touch events also create
    # mouse events for backwards compatibility.

    # For larger touch screens such as tablets or laptops, we want autofocus on
    # the select bar
    Store.state.hasTouch = Math.min($(window).width(), $(window).height()) < 600

  useEffect ->
    Store.onChange ->
      setUpdate (prev) -> prev + 1

    Store.onNavigate ->
      newState = parseUrl()
      setPage newState.page
      setItemId newState.itemId
      setTagId newState.tagId
      setSearch newState.search || ''
      window.scrollTo 0, 0

    window.addEventListener 'popstate', (e) ->
      newState = parseUrl()
      setPage newState.page
      setItemId newState.itemId
      setTagId newState.tagId
      setSearch newState.search || ''
      if e.state.scrollPos?
        window.requestAnimationFrame ->
          window.scrollTo 0, e.state.scrollPos

    window.addEventListener 'keyup', onKeyUp

    document.addEventListener 'dragenter', onGlobalDragEnter
    document.addEventListener 'dragleave', onGlobalDragLeave
    document.addEventListener 'dragover', onGlobalDragOver
    document.addEventListener 'drop', onGlobalDrop

    ->
      document.removeEventListener 'dragenter', onGlobalDragEnter
      document.removeEventListener 'dragleave', onGlobalDragLeave
      document.removeEventListener 'dragover', onGlobalDragOver
      document.removeEventListener 'drop', onGlobalDrop
  , []

  if page == 'home'
    return <div><NavBar initialSearch={search} showingResults={false} /><ErrorBoundary><Home/></ErrorBoundary></div>

  if page == 'tags'
    return <div><NavBar initialSearch={search} showingResults={false} /><ErrorBoundary><TagList/></ErrorBoundary></div>

  if page == 'upload'
    return <div><NavBar initialSearch={search} showingResults={false} /><ErrorBoundary><Upload ref={uploaderRef}/></ErrorBoundary></div>

  if page == 'tag'
    tag = Store.state.tagsById[tagId]
    if !tag
      if Store.state.tags.length > 0
        return <div><NavBar initialSearch={search} showingResults={false} /><h1>Tag not found</h1></div>
      else
        return <div><NavBar initialSearch={search} showingResults={false} /><div>Loading...</div></div>

    return <div><NavBar initialSearch={search} showingResults={false} /><ErrorBoundary><TagEditor tag={tag}/></ErrorBoundary></div>

  unless page == 'item' || page == 'search'
    return <div><NavBar initialSearch={search} showingResults={false} /><div>Routing error for {page}</div></div>

  showSelection = Store.state.selectionCount > 0 || Store.state.selectMode
  showItem = page == 'item' && itemId != null

  # The overflow-y parameter on the html tag needs to be set BEFORE
  # Results.initialState is called.  That's because having a scrollbar appear
  # doesn't cause a resize event to fire (and even if it did, it'd be too
  # late to properly calculate our desired scroll position)
  document.documentElement.style.overflowY = if showItem
    'auto'
  else
    'scroll'

  classes = ['react-wrapper']
  classes.push 'showing-details' if showItem
  classes.push 'showing-upload' if draggingCount > 0

  <div className={classes.join ' '} onTouchStart={onTouchStart}>
    {
      if !showItem && !showSelection
        <NavBar initialSearch={search} showingResults={true} />
      else if showSelection
        <SelectBar showZoom={!showItem} fixed={!showItem}/>
    }
    {
      if showItem
        <ErrorBoundary><Details itemId={itemId} search={search}/></ErrorBoundary>
      else
        <ErrorBoundary><Results key="res"/></ErrorBoundary>
    }
    {
      if draggingCount > 0
        <div className="global-upload-overlay">
          <div className="upload-message">
            <i className="fa fa-cloud-upload fa-3x"/>
            <p>Drop files to upload</p>
          </div>
        </div>
    }
  </div>
