component 'NavBar', ({showingResults}) ->
  [hidden, setHidden] = React.useState false
  [showSearchHelper, setShowSearchHelper] = React.useState false
  [spacerHeight, setSpacerHeight] = React.useState 0
  prevTopRef = React.useRef null
  siteIconRef = React.useRef null
  navbarRef = React.useRef null

  updateSpacerHeight = ->
    if navbarRef.current?
      height = navbarRef.current.offsetHeight
      setSpacerHeight height

  useEffect ->
    # Initial height update
    updateSpacerHeight()

    # Create resize observer
    resizeObserver = new ResizeObserver ->
      updateSpacerHeight()

    # Start observing the navbar
    if navbarRef.current?
      resizeObserver.observe navbarRef.current

    # Cleanup
    -> resizeObserver.disconnect()
  , []

  onScroll = React.useCallback (e) ->
    top = window.pageYOffset

    if prevTopRef.current?
      if prevTopRef.current < top
        newHidden = true
      else if prevTopRef.current > top
        newHidden = false
      else
        newHidden = hidden

    # if we are within 100 pixels of the top, always show
    newHidden = false if top <= 100
    newHidden = false if showSearchHelper

    if newHidden? && hidden != newHidden
      setHidden newHidden

    prevTopRef.current = top
  , [hidden, showSearchHelper]

  useEffect ->
    window.addEventListener 'scroll', onScroll, false
    -> window.removeEventListener 'scroll', onScroll, false
  , [onScroll]

  toggleTags = ->
    Store.state.tagEditor = !Store.state.tagEditor
    Store.needsRedraw()

  onSelectMode = ->
    Store.state.openStack.push 'select'
    Store.state.selectMode = true
    Store.needsRedraw()

  onToggleSearchHelper = ->
    setShowSearchHelper !showSearchHelper

  closeSearchHelper = ->
    setShowSearchHelper false

  siteIcon = ->
    return siteIconRef.current if siteIconRef.current?
    elem = document.querySelector 'link[rel=icon]'
    siteIconRef.current = elem.href

  classes = ['navbar', 'navbar-expand-lg', 'navbar-light', 'bg-light', 'fixed-top']
  classes.push 'navbar-hidden' if hidden

  <div>
    <div style={height: "#{spacerHeight}px"}></div>
    <nav id="main-navbar" ref={navbarRef} className={classes.join ' '}>
      <div className="container-fluid">
        <Link className="navbar-brand" href="/" onClick={closeSearchHelper}>
          <img style={height: '20px'} src={siteIcon()}/>
        </Link>
        <button type="button" onClick={onToggleSearchHelper} className="btn btn-outline-secondary me-2 search-button">
          <i className="fa fa-search fa-fw"/>
          {" #{Store.state.query} "}
          {
            if Store.state.resultCount != null
              <span className="badge bg-secondary">{Store.state.resultCount.toLocaleString()}</span>
          }
        </button>
        <div className="ms-auto d-flex gap-2">
          {
            if showingResults
              <React.Fragment>
                <Zoom/>
                <button title="Select Mode" type="button" onClick={onSelectMode} className="btn me-2">
                  <i className="fa fa-check-square"/>
                </button>
              </React.Fragment>
          }
          <button type="button" className="btn dropdown-toggle" data-bs-toggle="dropdown" aria-expanded="false">
            <i className="fa fa-ellipsis-v"/>
          </button>
          <ul className="dropdown-menu dropdown-menu-end">
            <li><Link className="dropdown-item" href="/tags">Tags</Link></li>
            <li><Link className="dropdown-item" href="/places">Places</Link></li>
            <li><Link className="dropdown-item" href="/upload">Upload</Link></li>
            {
              if Store.state.isAdmin
                <li><Link className="dropdown-item" href="/admin">Admin</Link></li>
            }
            <li>
              <a className="dropdown-item" href="https://www.rickety.us/sundry/hypercheese-help/">Help</a>
            </li>
            <li>
              <a className="dropdown-item" href="/users/sign_out" data-method="delete" rel="nofollow">Sign out</a>
            </li>
          </ul>
        </div>
      </div>
    </nav>
    {
      if showSearchHelper
        <div className="search-helper-float">
          <SearchHelper spacerHeight={spacerHeight} close={closeSearchHelper}/>
        </div>
    }
  </div>
