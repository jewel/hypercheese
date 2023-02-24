@SearchHelper = createReactClass
  getInitialState: ->
    q = new SearchQuery
    q.parse Store.state.query

    query: q
    userInput: null
    showCriteriaPicker: false
    caretPosition: 0

  onShowCriteriaPicker: (e) ->
    e.preventDefault()
    @setState
      showCriteriaPicker: !@state.showCriteriaPicker

  onSelectCriteria: (e, opt) ->
    e.preventDefault()
    @state.query.options[opt] = if SearchQuery.multiple[opt]
      []
    else if SearchQuery.keywords[opt]
      true
    else
      ""

    @setState
      query: @state.query
      showCriteriaPicker: false

  onClearText: (e) ->
    @state.query.parse '', 0
    @setState
      userInput: ''
      query: @state.query
    @refs.search.focus()

  onChangeCriteriaValue: (e, opt) ->
    if SearchQuery.multiple[opt]
      values = e.target.value.split /,/
      values = [] if e.target.value == ""
      @state.query.options[opt] = values
    else
      @state.query.options[opt] = e.target.value

    @setState
      query: @state.query

  changeUserInput: (e) ->
    @state.query.parse e.target.value, e.target.selectionStart
    @setState
      userInput: e.target.value
      query: @state.query
      caretPosition: e.target.selectionStart

  onFocus: ->
    @setState
      userInput: @state.query.stringify()

  onBlur: ->
    @setState
      userInput: null
      caretPosition: null

  onSearch: (e) ->
    e.preventDefault()
    if @state.query.unknown.length > 0
      # Show errors
      @setState
        userInput: null

      return

    @props.close()
    str = @state.query.stringify()
    # Force search since we might be visiting the same URL that we're already
    # at, with the same search they already did.  (The user might be trying to
    # refresh the results.)
    Store.search str, true
    Store.navigate '/search/' + encodeURI(str)

  moveCaret: (e) ->
    @changeUserInput(e)

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
          <div className="input-group">
            <input
              ref="search"
              className="form-control"
              placeholder="Search"
              value={string}
              onChange={@changeUserInput}
              onClick={@moveCaret}
              onKeyUp={@moveCaret}
              onFocus={@onFocus}
              onBlur={@onBlur}
              type="text"
            />
            <span className="input-group-btn">
              <button type="button" className="btn btn-secondary" onClick={@onClearText}>&times;</button>
            </span>
          </div>
          {' '}
          <button className="btn btn-default btn-primary">
            <i className="fa fa-search"/> Search
          </button>
          <a href="javascript:void(0)" onClick={@onShowCriteriaPicker} className="btn">
            advanced...
          </a>
        </div>
        {
          if !@state.userInput? && query.unknown.length > 0
            <div className="alert alert-danger" role="alert">
              <strong>Unknown words:</strong> {query.unknown.join(', ')}
            </div>
        }
        {
          Object.keys(@state.query.options).map (key) =>
            <div key={key}>
              {key}: <input className="form-control" type="text" value={query.options[key]} onChange={ (e) => @onChangeCriteriaValue e, key }/>
            </div>
        }
        <div>
          {
            if @state.showCriteriaPicker
              SearchQuery.optionList.map (opt) =>
                <button key={opt} className="btn btn-default" onClick={ (e) => @onSelectCriteria e, opt }>{opt}</button>
          }
        </div>
      </form>
      <div className="tag-list">
        {
          used = {}
          others = {}
          query.tags.map (tag) =>
            used[tag.id] = true
          query.others.map (tag) =>
            others[tag.id] = true
          Store.state.tags.map (tag) =>
            selected = used[tag.id]
            if query.useOthers && !others[tag.id] && !used[tag.id]
              return
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

            <Tag tag={tag} key={tag.id} selected={selected} label onClick={onClick}/>
        }
      </div>
    </div>
