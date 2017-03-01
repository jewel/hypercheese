@ShareApp = React.createClass
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
      Store.state.showItem = null
      Store.needsRedraw()

  parseUrl: ->
    path = window.location.pathname
    parts = path.split('/')
    if parts.length == 3
      return {
        page: 'search'
        search: parts[2]
      }

    if parts.length == 4
      return {
        page: 'item'
        itemId: parseInt(parts[3], 10)
        search: parts[2]
      }

    alert "Invalid URL: #{path}"
    return {}


  render: ->

    showItem = @state.page == 'item' && @state.itemId != null
    classes = ['react-wrapper']
    classes.push 'showing-details' if showItem


    <div className={classes.join ' '}>
      {
        if showItem
          <Details itemId={@state.itemId} search={@state.search} viewonly=true />
        else
          [
            <NavBar key="navbar" />
            <Results key="res" />
          ]
      }
    </div>
