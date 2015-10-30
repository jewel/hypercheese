@NavBar = React.createClass
  getInitialState: ->
    newSearch: @props.search
    hidden: false

  componentDidMount: ->
    window.addEventListener 'scroll', @onScroll, false

  componentWillUnmount: ->
    window.removeEventListener 'scroll', @onScroll, false

  onScroll: (e) ->
    top = document.documentElement.scrollTop

    if @prevTop?
      if @prevTop < top
        newHidden = true
      else if @prevTop > top
        newHidden = false
      else
        newHidden = @state.hidden

    # if we are within 100 pixels of the top, always show

    newHidden = false if top <= 100

    if @state.hidden != newHidden
      @setState
        hidden: newHidden

    @prevTop = top

  changeNewSearch: (e) ->
    @setState
      newSearch: e.target.value

  onSearch: (e) ->
    e.preventDefault()
    if @state.newSearch == ''
      window.location.hash = '/'
    else
      window.location.hash = '/search/' + encodeURI(@state.newSearch)

  render: ->
    classes = ['navbar', 'navbar-default', 'navbar-fixed-top']
    if @state.hidden
      classes.push 'navbar-hidden'

    <div>
      <nav style={visibility: 'invisible'} className="navbar navbar-static-top"></nav>
      <nav id="main-navbar" className={classes.join ' '}>
        <div className="container-fluid">
          <div className="navbar-header">
            <button className="navbar-toggle collapsed" type="button" data-toggle="collapse" data-target="#hypercheese-navbar-collapse-1">
              <span className="sr-only">
                Toggle Navigation
              </span>
              <span className="icon-bar"></span>
              <span className="icon-bar"></span>
              <span className="icon-bar"></span>
            </button>
            <a className="navbar-brand">HyperCheese</a>
          </div>

          <div className="collapse navbar-collapse" id="hypercheese-navbar-collapse-1">
            <ul className="nav navbar-nav"></ul>

            <div>
              <ul className="nav navbar-nav">
                <li>
                  <a href="#/tags">Tags</a>
                </li>
              </ul>
              <form className="navbar-form navbar-left" role="Search" onSubmit={@onSearch}>
                <div className="form-group">
                  <input className="form-control" placeholder="Search" defaultValue={Store.state.query} value={@state.newSearch} onChange={@changeNewSearch} type="text"/>
                </div>
              </form>
              <p className="navbar-text">
                Count: {Store.state.resultCount}
              </p>
            </div>

            <ul className="nav navbar-nav navbar-right">
              <li>
                <a href="http://www.rickety.us/sundry/hypercheese-help/">Help</a>
              </li>
              <li>
                <a href="/users/sign_out" data-method="delete" rel="nofollow">Sign out</a>
              </li>
            </ul>
          </div>
        </div>
      </nav>
    </div>
