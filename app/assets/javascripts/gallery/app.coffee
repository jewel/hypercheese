# Router-enabled pages
component 'HomePage', ->
  <div>
    <NavBar initialSearch="" showingResults={false} />
    <ErrorBoundary>
      <Home/>
    </ErrorBoundary>
  </div>

component 'TagsPage', ->
  <div>
    <NavBar initialSearch="" showingResults={false} />
    <ErrorBoundary>
      <TagList/>
    </ErrorBoundary>
  </div>

component 'TagPage', ->
  {id} = useParams()
  tag = Store.state.tagsById[id]
  
  if !tag
    if Store.state.tags.length > 0
      return <div>
        <NavBar initialSearch="" showingResults={false} />
        <h1>Tag not found</h1>
      </div>
    else
      return <div>
        <NavBar initialSearch="" showingResults={false} />
        <div>Loading...</div>
      </div>

  <div>
    <NavBar initialSearch="" showingResults={false} />
    <ErrorBoundary>
      <TagEditor tag={tag}/>
    </ErrorBoundary>
  </div>

component 'UploadPage', ->
  [draggingCount, setDraggingCount] = React.useState(0)
  uploaderRef = React.useRef(null)

  onGlobalDragEnter = (e) ->
    e.preventDefault()
    e.stopPropagation()
    if e.dataTransfer.types.includes('Files')
      setDraggingCount((prev) -> prev + 1)

  onGlobalDragLeave = (e) ->
    e.preventDefault()
    e.stopPropagation()
    setDraggingCount((prev) -> prev - 1)

  onGlobalDragOver = (e) ->
    e.preventDefault()
    e.stopPropagation()

  onGlobalDrop = (e) ->
    e.preventDefault()
    e.stopPropagation()
    setDraggingCount(0)
    
    if e.dataTransfer.files.length > 0
      uploaderRef.current?.addFiles(e.dataTransfer.files)

  useEffect ->
    document.addEventListener('dragenter', onGlobalDragEnter)
    document.addEventListener('dragleave', onGlobalDragLeave)
    document.addEventListener('dragover', onGlobalDragOver)
    document.addEventListener('drop', onGlobalDrop)

    ->
      document.removeEventListener('dragenter', onGlobalDragEnter)
      document.removeEventListener('dragleave', onGlobalDragLeave)
      document.removeEventListener('dragover', onGlobalDragOver)
      document.removeEventListener('drop', onGlobalDrop)
  , []

  classes = ['react-wrapper']
  classes.push('showing-upload') if draggingCount > 0

  <div className={classes.join(' ')}>
    <NavBar initialSearch="" showingResults={false} />
    <ErrorBoundary>
      <Upload ref={uploaderRef}/>
    </ErrorBoundary>
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

component 'SearchPage', ->
  {query} = useParams()
  [update, setUpdate] = React.useState(0)
  [draggingCount, setDraggingCount] = React.useState(0)
  navigate = useNavigate()
  uploaderRef = React.useRef(null)

  # Decode the search query
  searchQuery = if query then decodeURIComponent(query) else ''

  # Update search when query changes
  useEffect ->
    if searchQuery
      Store.search(searchQuery)
      document.title = "Hypercheese: #{searchQuery}"
    else
      document.title = "Hypercheese"
  , [searchQuery]

  onGlobalDragEnter = (e) ->
    e.preventDefault()
    e.stopPropagation()
    if e.dataTransfer.types.includes('Files')
      setDraggingCount((prev) -> prev + 1)

  onGlobalDragLeave = (e) ->
    e.preventDefault()
    e.stopPropagation()
    setDraggingCount((prev) -> prev - 1)

  onGlobalDragOver = (e) ->
    e.preventDefault()
    e.stopPropagation()

  onGlobalDrop = (e) ->
    e.preventDefault()
    e.stopPropagation()
    setDraggingCount(0)
    
    if e.dataTransfer.files.length > 0
      navigate('/upload')
      uploaderRef.current?.addFiles(e.dataTransfer.files)

  useEffect ->
    Store.onChange ->
      setUpdate((prev) -> prev + 1)

    document.addEventListener('dragenter', onGlobalDragEnter)
    document.addEventListener('dragleave', onGlobalDragLeave)
    document.addEventListener('dragover', onGlobalDragOver)
    document.addEventListener('drop', onGlobalDrop)

    ->
      document.removeEventListener('dragenter', onGlobalDragEnter)
      document.removeEventListener('dragleave', onGlobalDragLeave)
      document.removeEventListener('dragover', onGlobalDragOver)
      document.removeEventListener('drop', onGlobalDrop)
  , []

  showSelection = Store.state.selectionCount > 0 || Store.state.selectMode

  classes = ['react-wrapper']
  classes.push('showing-upload') if draggingCount > 0

  <div className={classes.join(' ')}>
    {
      if !showSelection
        <NavBar initialSearch={searchQuery} showingResults={true} />
      else
        <SelectBar showZoom={true} fixed={true}/>
    }
    <ErrorBoundary>
      <Results key="res"/>
    </ErrorBoundary>
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

component 'ItemPage', ->
  {id} = useParams()
  location = useLocation()
  [update, setUpdate] = React.useState(0)
  [draggingCount, setDraggingCount] = React.useState(0)
  navigate = useNavigate()
  uploaderRef = React.useRef(null)

  itemId = parseInt(id)
  
  # Get search query from URL state or default to empty
  searchQuery = location.state?.search || ''

  onGlobalDragEnter = (e) ->
    e.preventDefault()
    e.stopPropagation()
    if e.dataTransfer.types.includes('Files')
      setDraggingCount((prev) -> prev + 1)

  onGlobalDragLeave = (e) ->
    e.preventDefault()
    e.stopPropagation()
    setDraggingCount((prev) -> prev - 1)

  onGlobalDragOver = (e) ->
    e.preventDefault()
    e.stopPropagation()

  onGlobalDrop = (e) ->
    e.preventDefault()
    e.stopPropagation()
    setDraggingCount(0)
    
    if e.dataTransfer.files.length > 0
      navigate('/upload')
      uploaderRef.current?.addFiles(e.dataTransfer.files)

  onKeyUp = (e) ->
    if e.keyCode == 27
      while lastOpened = Store.state.openStack.pop()
        if lastOpened == 'item'
          navigate(-1)
          break
        if lastOpened == 'select' && Store.state.selectionCount > 0 || Store.state.selectMode
          Store.state.selectMode = false
          Store.clearSelection()
          break

  useEffect ->
    Store.onChange ->
      setUpdate((prev) -> prev + 1)

    window.addEventListener('keyup', onKeyUp)
    document.addEventListener('dragenter', onGlobalDragEnter)
    document.addEventListener('dragleave', onGlobalDragLeave)
    document.addEventListener('dragover', onGlobalDragOver)
    document.addEventListener('drop', onGlobalDrop)

    ->
      window.removeEventListener('keyup', onKeyUp)
      document.removeEventListener('dragenter', onGlobalDragEnter)
      document.removeEventListener('dragleave', onGlobalDragLeave)
      document.removeEventListener('dragover', onGlobalDragOver)
      document.removeEventListener('drop', onGlobalDrop)
  , []

  useEffect ->
    # Set document overflow for item view
    document.documentElement.style.overflowY = 'auto'
    window.scrollTo(0, 0)
    
    ->
      document.documentElement.style.overflowY = 'scroll'
  , []

  showSelection = Store.state.selectionCount > 0 || Store.state.selectMode

  classes = ['react-wrapper', 'showing-details']
  classes.push('showing-upload') if draggingCount > 0

  <div className={classes.join(' ')}>
    {
      if showSelection
        <SelectBar showZoom={false} fixed={false}/>
    }
    <ErrorBoundary>
      <Details itemId={itemId} search={searchQuery}/>
    </ErrorBoundary>
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

component 'GalleryApp', withErrorBoundary ->
  navigate = useNavigate()
  
  onTouchStart = ->
    # For larger touch screens such as tablets or laptops, we want autofocus on
    # the select bar
    Store.state.hasTouch = Math.min($(window).width(), $(window).height()) < 600

  useEffect ->
    # Initialize Store with navigation callback
    Store.setNavigate(navigate)
    
    # Handle initial search if we're on a search page
    pathname = window.location.pathname
    if pathname.startsWith('/search/')
      parts = pathname.split('/')
      if parts[2]
        searchQuery = decodeURIComponent(parts[2])
        Store.search(searchQuery)
  , []

  <div onTouchStart={onTouchStart}>
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/tags" element={<TagsPage />} />
      <Route path="/tags/:id" element={<TagPage />} />
      <Route path="/upload" element={<UploadPage />} />
      <Route path="/search" element={<SearchPage />} />
      <Route path="/search/:query" element={<SearchPage />} />
      <Route path="/items/:id" element={<ItemPage />} />
      <Route path="*" element={<div><NavBar initialSearch="" showingResults={false} /><div>Page not found</div></div>} />
    </Routes>
  </div>

component 'GalleryAppRoot', ->
  <BrowserRouter>
    <GalleryApp />
  </BrowserRouter>
