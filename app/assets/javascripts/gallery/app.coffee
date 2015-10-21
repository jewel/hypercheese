#= require ./navbar
#= require ./item

@GalleryApp = React.createClass
  getInitialState: ->
    tags: []
    searchQuery: ""
    results: Ember.Object.create()
    scrollTop: $('.scroll-window').scrollTop()

  componentDidMount: ->
    Bridge.onChange (data) =>
      @setState(data)

  componentWillUnmount: ->
    @window[0].removeEventListener 'scroll', @onScroll, false
    @window[0].removeEventListener 'resize', @updateViewPort, false

  render: ->
    <div className="react-wrapper">
      <NavBar results={@state.results}/>
      <Results results={@state.results}/>
    </div>
