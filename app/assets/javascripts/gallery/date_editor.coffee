component 'DateEditor', ({itemId, currentDate, fuzzyDate, onSave, onCancel}) ->
  [editing, setEditing] = useState false
  [inputValue, setInputValue] = useState fuzzyDate || ''
  [examples, setExamples] = useState false

  onEdit = ->
    setEditing true
    setInputValue fuzzyDate || ''

  onSaveClick = ->
    Store.updateItemDate itemId, inputValue
    setEditing false
    onSave?()

  onCancelClick = ->
    setEditing false
    setInputValue fuzzyDate || ''
    onCancel?()

  onInputChange = (e) ->
    setInputValue e.target.value

  onKeyDown = (e) ->
    if e.key == 'Enter'
      onSaveClick()
    else if e.key == 'Escape'
      onCancelClick()

  toggleExamples = ->
    setExamples !examples

  displayDate = ->
    if fuzzyDate
      fuzzyDate
    else
      new Date(currentDate).toLocaleString()

  if editing
    <div className="date-editor">
      <div className="input-group">
        <input
          type="text"
          className="form-control"
          value={inputValue}
          onChange={onInputChange}
          onKeyDown={onKeyDown}
          placeholder="Enter fuzzy date (e.g., 1985, 1980s, 1985-03, 1985 #3)"
          autoFocus
        />
        <div className="input-group-btn">
          <button className="btn btn-success" onClick={onSaveClick}>
            <i className="fa fa-check"/>
          </button>
          <button className="btn btn-default" onClick={onCancelClick}>
            <i className="fa fa-times"/>
          </button>
        </div>
      </div>
      <div className="help-block">
        <small>
          <a href="#" onClick={toggleExamples}>
            <i className="fa fa-question-circle"/> Examples
          </a>
        </small>
        {
          if examples
            <div className="examples">
              <strong>Supported formats:</strong>
              <ul>
                <li><code>1985</code> - Year</li>
                <li><code>1980s</code> - Decade</li>
                <li><code>1985-03</code> - Month</li>
                <li><code>1985-03-15</code> - Day</li>
                <li><code>1985 #3</code> - Year with sort order</li>
                <li><code>1985-03 #2</code> - Month with sort order</li>
              </ul>
              <p><small>The <code>#</code> number helps sort photos when you know the order but not exact dates.</small></p>
            </div>
        }
      </div>
    </div>
  else
    <span className="date-display">
      {displayDate()}
      {' '}
      <Writer>
        <a href="#" onClick={onEdit} className="edit-date">
          <i className="fa fa-edit"/>
        </a>
      </Writer>
    </span>