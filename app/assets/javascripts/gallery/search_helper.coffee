@SearchHelper = React.createClass
  getInitialState: ->
    newSearch: Store.state.query

  changeNewSearch: (e) ->
    @setState
      newSearch: e.target.value

  updateSearch: (str) ->
    @setState
      newSearch: str

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

    <div className="search-helper">
      <form onSubmit={@onSearch} className="form-inline">
        <div className="form-group">
          <input className="form-control" placeholder="Search" value={@state.newSearch} onChange={@changeNewSearch} type="text"/>
          {' '}
          <button className="btn btn-default btn-primary">
            <i className="fa fa-search"/> Search
          </button>
        </div>
        {
          if query.unknown.length > 0
            <div className="alert alert-danger" role="alert">
              <strong>Unknown words:</strong> {query.unknown.join(', ')}
            </div>
        }
        <div className="tag-list">
          {
            query.tags.map (tag) ->
              <Tag tag=tag key={tag.id}/>
          }
        </div>
        {
          res = []
          for k, v of query.options
            res.push <div key=k>{"#{k}: #{v}"}</div>
          res
        }
      </form>
      <div className="tag-list">
        {
          Store.state.tags.map (tag) =>
            <Tag key={tag.id} tag=tag label/>
        }
      </div>
    </div>
