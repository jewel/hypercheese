@GalleryApp = React.createClass
  getInitialState: ->
    state = @parseUrl()
    state.search ||= ''
    state.update = 0
    state

  componentDidMount: ->
    Store.onChange =>
      # FIXME React should batch these to only have one render event, but that
      # does not seem to be working.
      @setState
        update: @state.update + 1

    Store.onNavigate =>
      @setState @parseUrl()
      window.scrollTo 0, 0

    window.addEventListener 'popstate', (e) =>
      @setState @parseUrl()
      if e.state.scrollPos?
        window.requestAnimationFrame ->
          window.scrollTo 0, e.state.scrollPos

    window.addEventListener 'keyup', @onKeyUp

  onKeyUp: (e) ->
    if e.keyCode == 27
      while lastOpened = Store.state.openStack.pop()
        page = @state.page
        if lastOpened == 'info' && page == 'item' && Store.state.showInfo
          Store.state.showInfo = false
          Store.needsRedraw()
          break
        if lastOpened == 'item' && page == 'item'
          Store.navigateBack()
          break
        if lastOpened == 'select' && Store.state.selectionCount > 0 || Store.state.selectMode
          Store.state.selectMode = false
          Store.clearSelection()
          break


  parseUrl: ->
    path = window.location.pathname
    if path == '' || path == '/'
      return {
        page: 'home'
      }

    parts = path.split('/')
    if parts.length == 1 || parts[0] != ''
      console.warn "Invalid URL: #{path}"
      return {
        page: 'home'
      }

    if parts[1] == 'items'
      return {
        page: 'item'
        itemId: Math.round(parts[2])
      }

    if parts[1] == 'tags' && parts[2]
      return {
        page: 'tag'
        tagId: parts[2]
      }

    if parts[1] == 'tags'
      return {
        page: 'tags'
      }

    if parts[1] == 'search'
      str = decodeURI parts[2]
      Store.search str
      return {
        page: 'search'
        search: str
      }

    console.warn "Invalid URL: #{path}"
    return {
      page: 'home'
    }

  onTouchStart: ->
    # No way to flip-flop on this at the moment, since touch events also create
    # mouse events for backwards compatibility.

    # For larger touch screens such as tablets or laptops, we want autofocus on
    # the select bar
    Store.state.hasTouch = Math.min($(window).width(), $(window).height()) < 600

  render: ->
    if @state.page == 'home'
      return <div><NavBar initialSearch={@state.search} showingResults={false} /><Home/></div>

    if @state.page == 'tags'
      return <TagList/>

    if @state.page == 'tag'
      tag = Store.state.tagsById[@state.tagId]
      if !tag
        if Store.state.tags.length > 0
          return <h1>Tag not found</h1>
        else
          return <div>Loading...</div>

      return <TagEditor tag={tag}/>

    unless @state.page == 'item' || @state.page == 'search'
      return <div>Routing error for {@state.page}</div>

    showSelection = Store.state.selectionCount > 0 || Store.state.selectMode
    showItem = @state.page == 'item' && @state.itemId != null

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


    <div className={classes.join ' '} onTouchStart={@onTouchStart}>
      {
        if !showItem && !showSelection
          <NavBar initialSearch={@state.search} showingResults={true} />
        else if showSelection
          <SelectBar showZoom={!showItem} fixed={!showItem}/>
      }
      {
        if showItem
          <Details itemId={@state.itemId} search={@state.search}/>
        else
          <Results key="res"/>
      }
    </div>
