@SearchHelper = React.createClass
  getInitialState: ->
    q = new SearchQuery
    q.parse Store.state.query

    query: q
    userInput: null

  changeUserInput: (e) ->
    @state.query.parse e.target.value
    @setState
      userInput: e.target.value
      query: @state.query

  onFocus: ->
    @setState
      userInput: @state.query.stringify()

  onBlur: ->
    @setState
      userInput: null

  onSearch: (e) ->
    e.preventDefault()
    @props.close()
    window.location.hash = '/search/' + encodeURI(@state.query.stringify())

  optionHelper: (field, options...) ->
    val = ""
    <select className="form-control" defaultValue={val}>
      {
        options.map (opt) =>
          <option key={opt[0]} value={opt[0]}>{opt[1]}</option>
      }
    </select>

  render: ->
    query = @state.query
    string = if @state.userInput?
      @state.userInput
    else
      query.stringify()

    <div className="search-helper">
      <form onSubmit={@onSearch} className="form-inline">
        <div className="form-group">
          <input className="form-control" placeholder="Search" value={string} onChange={@changeUserInput} onFocus={@onFocus} onBlur={@onBlur} type="text"/>
          {' '}
          <button className="btn btn-default btn-primary">
            <i className="fa fa-search"/> Search
          </button>
        </div>
        {
          if !@state.userInput? && query.unknown.length > 0
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
          Store.state.tags.map (tag) =>
            selected = used[tag.id]
            if !used[tag.id]
              onClick = =>
                query.tags.push tag
                @setState
                  query: query
            else
              onClick = =>
                query.tags = query.tags.filter (e) -> e.id != tag.id
                @setState
                  query: query

            <Tag tag=tag key={tag.id} selected={selected} label onClick={onClick}/>
        }
      </div>
    </div>
