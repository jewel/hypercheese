@GalleryApp = React.createClass
  getInitialState: ->
    state = @parseHash()
    state.search ||= ''
    state

  componentDidMount: ->
    Store.onChange =>
      @forceUpdate()
    window.addEventListener 'hashchange', =>
      @setState @parseHash()

  parseHash: ->
    hash = window.location.hash.substr(1)
    if hash == '' || hash == '/'
      return {
        home: true
        tags: false
      }

    parts = hash.split('/')
    if parts.length == 1 || parts[0] != ''
      console.warn "Invalid URL: #{hash}"
      return {
        home: true
      }

    if parts[1] == 'items'
      return {
        itemId: Math.round(parts[2])
        tags: false
        home: false
      }

    if parts[1] == 'tags'
      return {
        tags: true
        home: false
      }

    if parts[1] == 'search'
      str = decodeURI parts[2]
      Store.search str
      return {
        itemId: null
        search: str
        tags: false
        home: false
      }

    console.warn "Invalid URL: #{hash}"
    return {
      home: true
    }

  render: ->
    selection = Store.state.selectionCount > 0 || Store.state.selecting
    item = @state.itemId != null

    # The overflow-y parameter on the html tag needs to be set BEFORE
    # Results.initialState is called.  That's because having a scrollbar appear
    # doesn't cause a resize event to fire (and even if it did, it'd be too
    # late to properly calculate our desired scroll position)
    document.documentElement.style.overflowY = if item
      'auto'
    else
      'scroll'

    classes = ['react-wrapper']
    classes.push 'showing-details' if item

    if @state.tags
      return <TagList/>

    if @state.home
      return <div><NavBar initialSearch={@state.search}/><Home/></div>

    <div className={classes.join ' '}>
      {
        if !item && !selection
          <NavBar initialSearch={@state.search} showZoom={true}/>
        else if selection
          <SelectBar showZoom={!item}/>
      }
      {
        if item
          <Details itemId={@state.itemId} search={@state.search}/>
        else
          <Results/>
      }
    </div>
