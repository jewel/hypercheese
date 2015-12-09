@SearchHelper = React.createClass
  getInitialState: ->
    newSearch: Store.state.query
    typing: false

  changeNewSearch: (e) ->
    @setState
      newSearch: e.target.value

  updateSearch: (str) ->
    @setState
      newSearch: str

  onFocus: ->
    @setState
      typing: true

  onBlur: ->
    @setState
      typing: false

  onSearch: (e) ->
    e.preventDefault()
    @props.close()
    window.location.hash = '/search/' + encodeURI(@state.newSearch)

  optionHelper: (field, options...) ->
    val = ""
    <select className="form-control" defaultValue={val}>
      {
        options.map (opt) =>
          <option key={opt[0]} value={opt[0]}>{opt[1]}</option>
      }
    </select>

  render: ->
    query = new SearchQuery
    query.parse @state.newSearch
    string = if @state.typing
      @state.newSearch
    else
      query.stringify()

    <div className="search-helper">
      <form onSubmit={@onSearch} className="form-inline">
        <div className="form-group">
          <input className="form-control" placeholder="Search" value={string} onChange={@changeNewSearch} onFocus={@onFocus} onBlur={@onBlur} type="text"/>
          {' '}
          <button className="btn btn-default btn-primary">
            <i className="fa fa-search"/> Search
          </button>
        </div>
        {
          if !@state.typing && query.unknown.length > 0
            <div className="alert alert-danger" role="alert">
              <strong>Unknown words:</strong> {query.unknown.join(', ')}
            </div>
        }
        {
          res = []
          for k, v of query.options
            res.push <div key=k>{"#{k}: #{v}"}</div>
          res
        }
      </form>
      <div className="tag-list">
        {
          used = {}
          query.tags.map (tag) =>
            used[tag.id] = true
            removeTag = =>
              @setState
                newSearch: @state.newSearch.replace( tag.label, '' )
            <Tag tag=tag key={tag.id} selected label onClick={removeTag}/>
        }
        {
          Store.state.tags.map (tag) =>
            return null if used[tag.id]
            addTag = =>
              @setState
                newSearch: @state.newSearch + " #{tag.label}"
            <Tag key={tag.id} tag=tag label onClick={addTag}/>
        }
      </div>
    </div>
