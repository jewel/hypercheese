component 'SearchHelper', ({close, spacerHeight}) ->
  [searchString, setSearchString] = React.useState Store.state.query
  [userInput, setUserInput] = React.useState null
  [showCriteriaPicker, setShowCriteriaPicker] = React.useState false
  [showTagPicker, setShowTagPicker] = React.useState false
  [tagPickerFilter, setTagPickerFilter] = React.useState ''
  [caretPosition, setCaretPosition] = React.useState 0
  searchRef = React.useRef()

  onShowCriteriaPicker = (e) ->
    e.preventDefault()
    setShowCriteriaPicker !showCriteriaPicker

  onShowTagPicker = (e) ->
    e.preventDefault()
    setShowTagPicker !showTagPicker
    setTagPickerFilter ''

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
    Store.search searchString, true
    Store.navigate '/search/' + encodeURI(searchString)

  onTagPickerFilterChange = (e) ->
    setTagPickerFilter e.target.value

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

  # Filter tags for tag picker
  getFilteredTagsForPicker = ->
    if tagPickerFilter == ''
      return Store.state.tags
    
    filter = tagPickerFilter.toLowerCase()
    Store.state.tags.filter (tag) ->
      (tag.alias || tag.label).toLowerCase().indexOf(filter) >= 0

  # Get tags to show in the main tag list (only matching ones)
  getTagsToShow = ->
    used = {}
    others = {}
    query.tags.map (tag) ->
      used[tag.id] = true
    query.others.map (tag) ->
      others[tag.id] = true

    # Only show matching tags when there's a query with partial matches
    if query.useOthers
      # Show matching tags (others) and already selected tags
      Store.state.tags.filter (tag) ->
        used[tag.id] || others[tag.id]
    else if query.tags.length > 0
      # If we have selected tags but no partial match, show only selected tags
      Store.state.tags.filter (tag) ->
        used[tag.id]
    else
      # No query or tags, show no tags
      []

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
        <a href="javascript:" onClick={onShowTagPicker} className="btn">
          <i className="fa fa-tags"/> browse tags
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
    
    {
      if showTagPicker
        <div className="tag-picker">
          <div className="tag-picker-header">
            <h4>Browse Tags</h4>
            <div className="input-group">
              <span className="input-group-addon"><i className="fa fa-search"/></span>
              <input 
                type="text" 
                className="form-control" 
                placeholder="Filter tags..."
                value={tagPickerFilter}
                onChange={onTagPickerFilterChange}
              />
            </div>
          </div>
          <div className="tag-picker-list">
            {
              getFilteredTagsForPicker().map (tag) ->
                used = {}
                query.tags.map (selectedTag) ->
                  used[selectedTag.id] = true
                
                selected = used[tag.id]
                
                onClick = ->
                  if !selected
                    query.tags.push tag
                    setSearchString query.stringify()
                  else
                    query.tags = query.tags.filter (e) -> e.id != tag.id
                    setSearchString query.stringify()

                <Tag tag={tag} key={tag.id} selected={selected} label onClick={onClick}/>
            }
          </div>
        </div>
    }

    <div className="tag-list">
      {
        getTagsToShow().map (tag) ->
          used = {}
          query.tags.map (selectedTag) ->
            used[selectedTag.id] = true
          
          selected = used[tag.id]
          
          onClick = ->
            if !selected
              query.tags.push tag
              setSearchString query.stringify()
            else
              query.tags = query.tags.filter (e) -> e.id != tag.id
              setSearchString query.stringify()

          <Tag tag={tag} key={tag.id} selected={selected} label onClick={onClick}/>
      }
    </div>
  </div>
