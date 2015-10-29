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
        itemId: parts[2]
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
    classes = ['react-wrapper']
    if @state.itemId
      classes.push 'show-details'

    <div className={classes.join ' '}>
      {
        if Store.state.selectionCount > 0
          <SelectBar/>
        else
          <NavBar search={@state.search}/>
      }
      <Results/>
      {
        if @state.itemId
          <Details itemId={@state.itemId} search={@state.search}/>
      }
    </div>
