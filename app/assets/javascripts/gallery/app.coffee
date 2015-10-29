@GalleryApp = React.createClass
  getInitialState: ->
    @parseHash()

  componentDidMount: ->
    Store.onChange =>
      @forceUpdate()
    window.addEventListener 'hashchange', =>
      @setState @parseHash()

  parseHash: ->
    hash = window.location.hash.substr(1)
    if hash == '' || hash == '/'
      Store.search ''
      return item_id: null

    parts = hash.split('/')
    if parts.length == 1 || parts[0] != ''
      console.warn "Invalid URL: #{hash}"
      return {}

    if parts[1] == 'items'
      return item_id: parts[2]

    if parts[1] == 'search'
      Store.search decodeURI(parts[2])
      return item_id: null

    console.warn "Invalid URL: #{hash}"
    return {}

  render: ->
    classes = ['react-wrapper']
    if @state.item_id
      classes.push 'show-details'

    <div className={classes.join ' '}>
      {
        if Store.state.selectionCount > 0
          <SelectBar/>
        else
          <NavBar/>
      }
      <Results/>
      {
        if @state.item_id
          <Details item_id={@state.item_id}/>
      }
    </div>
