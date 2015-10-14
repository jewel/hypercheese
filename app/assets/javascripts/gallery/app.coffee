#= require ./navbar
#= require ./item

@GalleryApp = React.createClass
  getInitialState: ->
    tags: []
    viewPortItems: []
    searchQuery: ""
    results: Ember.Object.create()
    scrollTop: $('.scroll-window').scrollTop()

  componentDidMount: ->
    # FIXME we shouldn't need to wait for document.ready, but we don't know how
    # to get to ember's store until then.
    $ =>
      Bridge.init()
      Bridge.onChange (data) =>
        @setState(data)

  componentWillUnmount: ->
    @window[0].removeEventListener 'scroll', @onScroll, false
    @window[0].removeEventListener 'resize', @updateViewPort, false

  render: ->
    <div className="react-wrapper">
      <NavBar/>
      <Results results={@state.results}/>
    </div>
