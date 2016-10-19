@ShareApp = React.createClass
  getInitialState: ->
    update: 0

  componentDidMount: ->
    Store.onChange =>
      # FIXME React should batch these to only have one render event, but that
      # does not seem to be working.
      @setState
        update: @state.update + 1

    window.addEventListener 'keyup', @onKeyUp

  onKeyUp: (e) ->
    if e.keyCode == 27
      Store.state.showItem = null
      Store.needsRedraw()

  render: ->
    showItem = Store.state.showItem

    classes = ['react-wrapper']
    classes.push 'showing-details' if showItem

    <div className={classes.join ' '}>
      {
        if showItem
          <Details itemId={showItem.id} search={@state.search} viewonly=true />
        else
          <Results />
      }
    </div>
