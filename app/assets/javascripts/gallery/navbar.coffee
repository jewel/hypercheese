@NavBar = createReactClass
  getInitialState: ->
    hidden: false
    showSearchHelper: false

  componentDidMount: ->
    window.addEventListener 'scroll', @onScroll, false

  componentWillUnmount: ->
    window.removeEventListener 'scroll', @onScroll, false

  toggleTags: ->
    Store.state.tagEditor = !Store.state.tagEditor
    Store.needsRedraw()

  onSelectMode: ->
    Store.state.openStack.push 'select'
    Store.state.selectMode = true
    Store.needsRedraw()

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

  onToggleSearchHelper: ->
    @setState
      showSearchHelper: !@state.showSearchHelper

  closeSearchHelper: ->
    @setState
      showSearchHelper: false

  siteIcon: ->
    return @_siteIcon if @_siteIcon?
    elem = document.querySelector 'link[rel=icon]'

    @_siteIcon = elem.href

  render: ->
    classes = ['navbar', 'navbar-default', 'navbar-fixed-top']
    if @state.hidden
      classes.push 'navbar-hidden'

    <div>
      <nav style={visibility: 'invisible'} className="navbar navbar-static-top"></nav>
      <nav id="main-navbar" className={classes.join ' '}>
        <div className="container-fluid">
          <Link className="navbar-brand" href="/" onClick={@closeSearchHelper}>
            <img style={height: '20px'} src={@siteIcon()}/>
          </Link>
          <a href="javascript:void(0)" onClick={@onToggleSearchHelper} className="btn navbar-btn btn-default search-button">
            <i className="fa fa-search fa-fw"/>
            {" #{Store.state.query} "}
            {
              if Store.state.resultCount != null
                <span className="badge">{Store.state.resultCount.toLocaleString()}</span>
            }
          </a>
          <a href="javascript:void(0)" className="btn navbar-btn dropdown-toggle pull-right" data-toggle="dropdown">
            <i className="fa fa-ellipsis-v"/>
          </a>
          {
            if @props.showingResults
              <a title="Select Mode" href="javascript:void(0)" onClick={@onSelectMode} className="btn navbar-btn pull-right">
                <i className="fa fa-check-square-o"/>
              </a>
          }
          <ul className="dropdown-menu pull-right">
            <li><Link href="/tags">Tags</Link></li>
            <li>
              <a href="http://www.rickety.us/sundry/hypercheese-help/">Help</a>
            </li>
            <li>
              <a href="/users/sign_out" data-method="delete" rel="nofollow">Sign out</a>
            </li>
          </ul>
          {
            if @props.showingResults
              <Zoom/>
          }
        </div>
      </nav>
      {
        if @state.showSearchHelper
          <div className="search-helper-float">
            <SearchHelper close={@closeSearchHelper}/>
          </div>
      }
    </div>
