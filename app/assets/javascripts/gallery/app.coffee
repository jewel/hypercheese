@GalleryApp = React.createClass
  getInitialState: ->
    item_id: null

  componentDidMount: ->
    Store.onChange =>
      @forceUpdate()

  showItem: (item_id) ->
    @setState
      item_id: item_id

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
      <Results showItem={@showItem}/>
      {
        if @state.item_id
          <Details showItem={@showItem} item_id={@state.item_id}/>
      }
    </div>
