@GalleryApp = React.createClass
  getInitialState: ->
    state = @parseHash()
    state.search ||= ''
    state

  updateScrollTop: (scrollTop) ->
    # exclude from state, we don't want to cause a redraw
    @oldScrollTop = scrollTop

  updateHighlight: (itemId) ->
    @setState
      highlight: itemId

  componentDidMount: ->
    Store.onChange =>
      @forceUpdate()
    window.addEventListener 'hashchange', =>
      @setState @parseHash()

  parseHash: ->
    hash = window.location.hash.substr(1)
    if hash == '' || hash == '/'
      Store.search ''
      return {
        search: ''
        itemId: null
      }

    parts = hash.split('/')
    if parts.length == 1 || parts[0] != ''
      console.warn "Invalid URL: #{hash}"
      return {}

    if parts[1] == 'items'
      return {
        itemId: Math.round(parts[2])
      }

    if parts[1] == 'search'
      str = decodeURI parts[2]
      Store.search str
      return {
        itemId: null
        search: str
      }

    console.warn "Invalid URL: #{hash}"
    return {}

  render: ->
    selection = Store.state.selectionCount > 0
    item = @state.itemId != null

    <div className='react-wrapper'>
      {
        if !item && !selection
          <NavBar search={@state.search}/>
        else if selection
          <SelectBar/>
      }
      {
        if item
          <Details itemId={@state.itemId} search={@state.search} updateHighlight={@updateHighlight}/>
        else
          <Results scrollTop={@oldScrollTop} updateScrollTop={@updateScrollTop} highlight={@state.highlight}/>
      }
    </div>
