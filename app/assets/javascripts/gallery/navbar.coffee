@NavBar = React.createClass
  getInitialState: ->
    newSearch: @props.initialSearch
    hidden: false
    showSearchHelper: false

  componentDidMount: ->
    window.addEventListener 'scroll', @onScroll, false

  componentWillUnmount: ->
    window.removeEventListener 'scroll', @onScroll, false

  toggleTags: ->
    Store.state.tagEditor = !Store.state.tagEditor
    Store.forceUpdate()

  onSelect: ->
    Store.state.selecting = true
    Store.forceUpdate()

  onScroll: (e) ->
    top = window.pageYOffset

    if @prevTop?
      if @prevTop < top
        newHidden = true
      else if @prevTop > top
        newHidden = false
      else
        newHidden = @state.hidden

    # if we are within 100 pixels of the top, always show

    newHidden = false if top <= 100
    newHidden = false if @state.showSearchHelper

    if newHidden? && @state.hidden != newHidden
      @setState
        hidden: newHidden

    @prevTop = top

  changeNewSearch: (e) ->
    @setState
      newSearch: e.target.value

  updateSearch: (str) ->
    @setState
      newSearch: str

  onFocusSearch: ->
    @setState
      showSearchHelper: true

  closeSearchHelper: ->
    @setState
      showSearchHelper: false

  onSearch: (e) ->
    e.preventDefault()
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
            <a href="#/" className="navbar-brand">HyperCheese</a>
          </div>

          <div className="collapse navbar-collapse" id="hypercheese-navbar-collapse-1">
            <ul className="nav navbar-nav"></ul>

            <div>
              <form className="navbar-form navbar-left">
                <a className="btn btn-default" onClick={@onSelect} href="javascript:void(0)">
                  Select...
                </a>
              </form>
              <ul className="nav navbar-nav">
                <li>
                  <a href="#/tags">Tags</a>
                </li>
              </ul>
              <form className="navbar-form navbar-left" role="Search" onSubmit={@onSearch}>
                <div className="form-group">
                  <input className="form-control" placeholder="Search" defaultValue={Store.state.query} value={@state.newSearch} onFocus={@onFocusSearch} onBlur={@closeSearchHelper} onChange={@changeNewSearch} type="text"/>
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

            {
              if @props.showZoom
                <Zoom/>
            }
          </div>
        </div>
      </nav>
      {
        if @state.showSearchHelper
          <div className="search-helper-float">
            <SearchHelper updateSearch={@updateSearch} close={@closeSearchHelper} search={@state.newSearch}/>
          </div>
      }
    </div>
