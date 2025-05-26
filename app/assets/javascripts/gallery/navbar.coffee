component 'NavBar', ({showingResults}) ->
  [hidden, setHidden] = React.useState false
  [showSearchHelper, setShowSearchHelper] = React.useState false
  prevTopRef = React.useRef null
  siteIconRef = React.useRef null

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

  classes = ['navbar', 'navbar-default', 'navbar-fixed-top']
  classes.push 'navbar-hidden' if hidden

  <div>
    <nav style={visibility: 'invisible'} className="navbar navbar-static-top"></nav>
    <nav id="main-navbar" className={classes.join ' '}>
      <div className="container-fluid">
        <Link className="navbar-brand" href="/" onClick={closeSearchHelper}>
          <img style={height: '20px'} src={siteIcon()}/>
        </Link>
        <button type="button" onClick={onToggleSearchHelper} className="btn navbar-btn btn-default search-button">
          <i className="fa fa-search fa-fw"/>
          {" #{Store.state.query} "}
          {
            if Store.state.resultCount != null
              <span className="badge">{Store.state.resultCount.toLocaleString()}</span>
          }
        </button>
        <div className="pull-right dropdown">
          <button type="button" className="btn navbar-btn dropdown-toggle" data-toggle="dropdown">
            <i className="fa fa-ellipsis-v"/>
          </button>
          {
            if showingResults
              <button title="Select Mode" type="button" onClick={onSelectMode} className="btn navbar-btn">
                <i className="fa fa-check-square-o"/>
              </button>
          }
          <ul className="dropdown-menu">
            <li><Link href="/tags">Tags</Link></li>
            <li><Link href="/upload">Upload</Link></li>
            {
              if Store.state.isAdmin
                <li><Link href="/admin">Admin</Link></li>
            }
            <li>
              <a href="https://www.rickety.us/sundry/hypercheese-help/">Help</a>
            </li>
            <li>
              <a href="/users/sign_out" data-method="delete" rel="nofollow">Sign out</a>
            </li>
          </ul>
        </div>
        {
          if showingResults
            <Zoom/>
        }
      </div>
    </nav>
    {
      if showSearchHelper
        <div className="search-helper-float">
          <SearchHelper close={closeSearchHelper}/>
        </div>
    }
  </div>
