@NavBar = createReactClass
  getInitialState: ->
    hidden: false

  siteIcon: ->
    return @_siteIcon if @_siteIcon?
    elem = document.querySelector 'link[rel=icon]'

    @_siteIcon = elem.href

  componentDidMount: ->
    window.addEventListener 'scroll', @onScroll, false

  componentWillUnmount: ->
    window.removeEventListener 'scroll', @onScroll, false

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

  render: ->
    classes = ['navbar', 'select-navbar', 'navbar-fixed-top']
    if @state.hidden
      classes.push 'navbar-hidden'

    <div>
      <nav style={visibility: 'invisible'} className="navbar navbar-static-top"></nav>
      <nav id="main-navbar" className={classes.join ' '}>
        <div className="container-fluid">
          <div className="navbar-brand">
            <img style={height: '20px'} src={@siteIcon()}/>
          </div>
          <div className="navbar-brand" style={color: 'white'}>
             {Store.state.items.length} items
          </div>
          <a href="/shares/#{Store.state.shareCode}/download" className="btn navbar-btn pull-right">
            <i className="fa fa-download"/> Download
          </a>
        </div>
      </nav>
    </div>
