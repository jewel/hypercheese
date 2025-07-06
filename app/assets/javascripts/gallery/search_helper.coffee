component 'SearchHelper', ({close, spacerHeight}) ->
  [searchString, setSearchString] = React.useState Store.state.query
  [userInput, setUserInput] = React.useState null
  [showCriteriaPicker, setShowCriteriaPicker] = React.useState false
  [showAdvancedOptions, setShowAdvancedOptions] = React.useState false
  [expandedSections, setExpandedSections] = React.useState {}
  [caretPosition, setCaretPosition] = React.useState 0
  searchRef = React.useRef()

  toggleSection = (sectionName) ->
    setExpandedSections (prev) ->
      { ...prev, [sectionName]: !prev[sectionName] }

  onShowCriteriaPicker = (e) ->
    e.preventDefault()
    setShowCriteriaPicker !showCriteriaPicker

  onToggleAdvancedOptions = (e) ->
    e.preventDefault()
    setShowAdvancedOptions !showAdvancedOptions

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

  onChangeOrientationValue = (value) ->
    query = new SearchQuery searchString, caretPosition
    query.options.orientation = value
    setSearchString query.stringify()

  onChangeTypeValue = (value) ->
    query = new SearchQuery searchString, caretPosition
    query.options.type = value
    setSearchString query.stringify()

  onChangeDateValue = (field, value) ->
    query = new SearchQuery searchString, caretPosition
    if value == ""
      delete query.options[field]
    else
      query.options[field] = [value]
    setSearchString query.stringify()

  onChangeMultiSelectValue = (field, selectedValues) ->
    query = new SearchQuery searchString, caretPosition
    query.options[field] = selectedValues
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

  renderTooltip = (text) ->
    <span className="tooltip-icon" title={text}>
      <i className="fa fa-question-circle"></i>
    </span>

  renderCollapsibleSection = (title, content, sectionKey) ->
    isExpanded = expandedSections[sectionKey]
    
    <div className="advanced-option-section">
      <div className="section-header" onClick={() -> toggleSection(sectionKey)}>
        <i className={"fa " + (if isExpanded then "fa-chevron-down" else "fa-chevron-right")}></i>
        <span className="section-title">{title}</span>
      </div>
      {if isExpanded then content else null}
    </div>

  renderOrientationControl = (currentValue) ->
    orientations = [
      { value: '', label: 'Any' },
      { value: 'landscape', label: 'Landscape' },
      { value: 'portrait', label: 'Portrait' },
      { value: 'square', label: 'Square' }
    ]
    
    <div className="form-group">
      <label className="control-label">
        Orientation
        {renderTooltip("Filter by image orientation")}
      </label>
      <div className="radio-group">
        {orientations.map (orientation) ->
          <label key={orientation.value} className="radio-inline">
            <input
              type="radio"
              name="orientation"
              value={orientation.value}
              checked={currentValue == orientation.value}
              onChange={(e) -> onChangeOrientationValue(e.target.value)}
            />
            {orientation.label}
          </label>
        }
      </div>
    </div>

  renderTypeControl = (currentValue) ->
    types = [
      { value: '', label: 'Any' },
      { value: 'photo', label: 'Photos' },
      { value: 'video', label: 'Videos' }
    ]
    
    <div className="form-group">
      <label className="control-label">
        Media Type
        {renderTooltip("Filter by photo or video")}
      </label>
      <select
        className="form-control"
        value={currentValue || ''}
        onChange={(e) -> onChangeTypeValue(e.target.value)}
      >
        {types.map (type) ->
          <option key={type.value} value={type.value}>{type.label}</option>
        }
      </select>
    </div>

  renderDateControl = (field, label, currentValue, tooltip) ->
    <div className="form-group">
      <label className="control-label">
        {label}
        {renderTooltip(tooltip)}
      </label>
      <input
        type="number"
        className="form-control"
        value={if currentValue && currentValue.length > 0 then currentValue[0] else ''}
        onChange={(e) -> onChangeDateValue(field, e.target.value)}
        placeholder={if field == 'year' then 'YYYY' else if field == 'month' then '1-12' else '1-31'}
        min={if field == 'year' then '1900' else if field == 'month' then '1' else '1'}
        max={if field == 'year' then '2099' else if field == 'month' then '12' else '31'}
      />
    </div>

  renderSourceControl = (currentValue) ->
    # For now, render as text input since we don't have easy access to sources
    # In a full implementation, this would be a multi-select dropdown
    <div className="form-group">
      <label className="control-label">
        Sources
        {renderTooltip("Filter by source (comma-separated)")}
      </label>
      <input
        type="text"
        className="form-control"
        value={if currentValue then currentValue.join(',') else ''}
        onChange={(e) -> onChangeCriteriaValue(e, 'source')}
        placeholder="Enter sources separated by commas"
      />
    </div>

  renderBooleanControl = (field, label, currentValue, tooltip) ->
    <div className="form-group">
      <label className="checkbox-inline">
        <input
          type="checkbox"
          checked={currentValue || false}
          onChange={(e) -> onChangeCriteriaValue(e, field)}
        />
        {label}
        {renderTooltip(tooltip)}
      </label>
    </div>

  renderTextControl = (field, label, currentValue, tooltip, placeholder = "") ->
    <div className="form-group">
      <label className="control-label">
        {label}
        {renderTooltip(tooltip)}
      </label>
      <input
        type="text"
        className="form-control"
        value={currentValue || ''}
        onChange={(e) -> onChangeCriteriaValue(e, field)}
        placeholder={placeholder}
      />
    </div>

  string = if userInput?
    userInput
  else
    searchString

  query = new SearchQuery searchString, caretPosition

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
        <a href="javascript:" onClick={onToggleAdvancedOptions} className="btn">
          <i className="fa fa-cog"/> Advanced Options
        </a>
      </div>
      {
        if !userInput? && query.unknown.length > 0
          <div className="alert alert-danger" role="alert">
            <strong>Unknown words:</strong> {query.unknown.join(', ')}
          </div>
      }
      {
        if showAdvancedOptions
          <div className="advanced-options">
            {renderCollapsibleSection("Media Options", 
              <div className="section-content">
                {renderOrientationControl(query.options.orientation)}
                {renderTypeControl(query.options.type)}
              </div>
            , "media")}
            
            {renderCollapsibleSection("Date & Time",
              <div className="section-content">
                {renderDateControl('year', 'Year', query.options.year, "Filter by year (e.g., 2023)")}
                {renderDateControl('month', 'Month', query.options.month, "Filter by month (1-12)")}
                {renderDateControl('day', 'Day', query.options.day, "Filter by day (1-31)")}
              </div>
            , "date")}
            
            {renderCollapsibleSection("Content & Tags",
              <div className="section-content">
                {renderBooleanControl('untagged', 'Untagged Items', query.options.untagged, "Show only items without tags")}
                {renderBooleanControl('has_comments', 'Has Comments', query.options.has_comments, "Show only items with comments")}
                {renderBooleanControl('starred', 'Starred Items', query.options.starred, "Show only starred items")}
                {renderBooleanControl('faces', 'Has Faces', query.options.faces, "Show only items with detected faces")}
                {renderTextControl('comment', 'Comment Contains', query.options.comment, "Search within comments", "Text to search in comments")}
              </div>
            , "content")}
            
            {renderCollapsibleSection("Sources & Paths",
              <div className="section-content">
                {renderSourceControl(query.options.source)}
                {renderTextControl('path', 'Path Contains', query.options.path, "Filter by file path", "Part of file path")}
              </div>
            , "sources")}
            
            {renderCollapsibleSection("Advanced Filters",
              <div className="section-content">
                {renderBooleanControl('any', 'Any Tag Match', query.options.any, "Match any of the selected tags instead of all")}
                {renderBooleanControl('only', 'Only Tagged Items', query.options.only, "Show only items with exactly the selected tags")}
                {renderBooleanControl('reverse', 'Reverse Order', query.options.reverse, "Reverse the sort order")}
                {renderTextControl('not', 'Exclude Tag', query.options.not, "Exclude items with this tag", "Tag to exclude")}
                {renderTextControl('threshold', 'Similarity Threshold', query.options.threshold, "Similarity threshold for AI search (0-100)", "0-100")}
              </div>
            , "advanced")}
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
