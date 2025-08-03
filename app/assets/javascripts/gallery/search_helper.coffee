component 'SearchHelper', ({close, spacerHeight, itemId}) ->
  [searchString, setSearchString] = React.useState Store.state.query
  [userInput, setUserInput] = React.useState null
  [showCriteriaPicker, setShowCriteriaPicker] = React.useState false
  [caretPosition, setCaretPosition] = React.useState 0
  [isLoading, setIsLoading] = React.useState false
  searchRef = React.useRef()

  onShowCriteriaPicker = (e) ->
    e.preventDefault()
    setShowCriteriaPicker !showCriteriaPicker

  onSelectCriteria = (e, opt) ->
    e.preventDefault()
    query = new SearchQuery searchString, caretPosition
    query.options[opt] = if SearchQuery.multiple[opt]
      []
    else if SearchQuery.keywords[opt]
      true
    else
      ""
    setSearchString query.stringify()
    setShowCriteriaPicker false

  onClearText = (e) ->
    setSearchString ''
    setUserInput ''
    searchRef.current?.focus()

  onChangeCriteriaValue = (e, opt) ->
    query = new SearchQuery searchString, caretPosition
    if SearchQuery.multiple[opt]
      values = e.target.value.split /,/
      values = [] if e.target.value == ""
      query.options[opt] = values
    else
      query.options[opt] = e.target.value
    setSearchString query.stringify()

  changeUserInput = (e) ->
    setUserInput e.target.value
    setCaretPosition e.target.selectionStart
    setSearchString e.target.value

  onFocus = ->
    setUserInput searchString

  onBlur = ->
    setUserInput null
    setCaretPosition null

  onSearch = (e) ->
    e.preventDefault()
    query = new SearchQuery searchString, caretPosition
    if query.unknown.length > 0
      setUserInput null
      return

    close()

    if itemId
      setIsLoading true
      Store.search searchString, true, itemId, (itemIndex) ->
        setIsLoading false
        if itemIndex?
          if searchString
            Store.navigate '/search/' + encodeURI(searchString) + '/' + itemId
          else
            Store.navigate '/items/' + itemId
        else
          Store.navigate '/search/' + encodeURI(searchString)
    else
      Store.search searchString, true
      Store.navigate '/search/' + encodeURI(searchString)

  optionHelper = (field, options...) ->
    val = ""
    <select className="form-control" defaultValue={val}>
      {
        options.map (opt) ->
          <option key={opt[0]} value={opt[0]}>{opt[1]}</option>
      }
    </select>

  string = if userInput?
    userInput
  else
    searchString

  query = new SearchQuery searchString, caretPosition

  if isLoading
    return <div className="search-helper" style={{paddingTop: spacerHeight}}>
      <div style={textAlign: 'center', margin: 48}>
        <i className="fa fa-spinner fa-spin" style={fontSize: 48}/>
      </div>
    </div>

  <div className="search-helper" style={{paddingTop: spacerHeight}}>
    <form onSubmit={onSearch} className="form-inline">
      <div className="form-group">
        <div className="input-group">
          <input
            ref={searchRef}
            className="form-control"
            placeholder="Search"
            value={string}
            onChange={changeUserInput}
            onFocus={onFocus}
            onBlur={onBlur}
            type="text"
          />
          <span className="input-group-btn">
            <button type="button" className="btn btn-secondary" onClick={onClearText}>&times;</button>
          </span>
        </div>
        {' '}
        <button className="btn btn-default btn-primary">
          <i className="fa fa-search"/> Search
        </button>
        <a href="javascript:" onClick={onShowCriteriaPicker} className="btn">
          advanced...
        </a>
      </div>
      {
        if !userInput? && query.unknown.length > 0
          <div className="alert alert-danger" role="alert">
            <strong>Unknown words:</strong> {query.unknown.join(', ')}
          </div>
      }
      {
        Object.keys(query.options).map (key) ->
          <div key={key}>
            {key}: <input className="form-control" type="text" value={query.options[key]} onChange={ (e) -> onChangeCriteriaValue e, key }/>
          </div>
      }
      <div>
        {
          if showCriteriaPicker
            SearchQuery.optionList.map (opt) ->
              <button key={opt} className="btn btn-default" onClick={ (e) -> onSelectCriteria e, opt }>{opt}</button>
        }
      </div>
    </form>
    <div className="tag-list">
      {
        used = {}
        others = {}
        query.tags.map (tag) ->
          used[tag.id] = true
        query.others.map (tag) ->
          others[tag.id] = true
        Store.state.tags.map (tag) ->
          selected = used[tag.id]
          if query.useOthers && !others[tag.id] && !used[tag.id]
            return
          if !used[tag.id]
            onClick = ->
              query.tags.push tag
              setSearchString query.stringify()
          else
            onClick = ->
              query.tags = query.tags.filter (e) -> e.id != tag.id
              setSearchString query.stringify()

          <Tag tag={tag} key={tag.id} selected={selected} label onClick={onClick}/>
      }
    </div>
  </div>
