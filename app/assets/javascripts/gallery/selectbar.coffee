component 'SelectBar', ({fixed}) ->
  [caretPosition, setCaretPosition] = useState 0
  [showTagLabels, setShowTagLabels] = useState false
  [spacerHeight, setSpacerHeight] = useState 0
  selectbarRef = React.useRef null

  updateSpacerHeight = ->
    if selectbarRef.current?
      height = selectbarRef.current.offsetHeight
      setSpacerHeight height

  useEffect ->
    # Initial height update
    updateSpacerHeight()

    # Create resize observer
    resizeObserver = new ResizeObserver ->
      updateSpacerHeight()

    # Start observing the selectbar
    if selectbarRef.current?
      resizeObserver.observe selectbarRef.current

    # Cleanup
    -> resizeObserver.disconnect()
  , []

  useEffect ->
    Store.state.openStack.push 'select'
    ->
  , []

  onExit = (e) ->
    Store.state.selectMode = false
    Store.clearSelection()

  shareSelection = (e) ->
    Store.shareSelection().then (url) ->
      window.prompt "The items are available at this link:", url

  publishSelection = (e) ->
    Store.changeSelectionVisibility true

  restrictSelection = (e) ->
    Store.changeSelectionVisibility false

  changeNewTags = (e) ->
    if e.target.value == '.'
      Store.addTagsToSelection Store.state.lastTags
      return

    Store.state.pendingTags = TagMatch.matchMany e.target.value, e.target.selectionStart
    Store.state.pendingTagString = e.target.value
    setCaretPosition e.target.selectionStart
    setShowTagLabels false
    Store.needsRedraw()

  moveCaret = (e) ->
    Store.state.pendingTags = TagMatch.matchMany Store.state.pendingTagString, e.target.selectionStart
    setCaretPosition e.target.selectionStart
    setShowTagLabels false

  addNewTags = (e) ->
    e.preventDefault()
    matches = []
    misses = []
    for part in Store.state.pendingTags
      matches.push part.match if part.match?
      misses.push part.miss if part.miss?

    if matches.length > 0
      Store.addTagsToSelection matches
    Store.state.pendingTags = []

    if misses.length == 0
      Store.state.pendingTagString = ""
      Store.clearSelection()
    else
      Store.state.pendingTagString = misses.join(', ')
      Store.needsRedraw()

  selectedTags = ->
    index = {}
    tags = []
    for id of Store.state.selection
      item = Store.getItem id
      if !item
        console.warn "Can't find item #{id}"
        continue
      for tag_id in item.tag_ids
        obj = index[tag_id]
        if !obj
          tag = Store.state.tagsById[tag_id]
          if !tag
            console.warn "Can't find tag #{tag_id}"
            continue
          obj = index[tag_id] =
            tag: tag
            count: 0
          tags.push obj
        obj.count++
    tags

  ids = []
  for id of Store.state.selection
    ids.push id

  downloadLink = "/api/items/download?ids=#{ids.join ','}"
  convertLink = "/api/items/convert?ids=#{ids.join ','}"
  tags = Store.state.pendingTags

  classes = ['navbar', 'select-navbar', 'navbar-expand-lg', 'navbar-light', 'bg-light']
  if fixed
    classes.push 'fixed-top'
  else
    classes.push 'static-top'

  helperClasses = ['tag-helper']
  if fixed
    helperClasses.push 'tag-helper-fixed'

  <div>
    {
      if fixed
        <div style={height: "#{spacerHeight}px"}></div>
    }
    <nav ref={selectbarRef} className={classes.join ' '}>
      <div className="container-fluid">
        <span className="navbar-text">{" #{Store.state.selectionCount.toLocaleString()} "}</span>
        <Writer>
          <form onSubmit={addNewTags}>
            <input className="form-control" placeholder="Add tags" value={Store.state.pendingTagString} onChange={changeNewTags} type="text" onClick={moveCaret} autoFocus={!Store.state.hasTouch} onKeyUp={moveCaret}/>
          </form>
        </Writer>

        <div className="ms-auto">
          <Writer>
            <button type="button" title="Share" className="btn me-2" onClick={shareSelection}><i className="fa fa-share-alt"/></button>
          </Writer>
          <a title="Download Originals" className="btn me-2" href={downloadLink}><i className="fa fa-download"/></a>
          <div className="btn-group me-2">
            <button type="button" className="btn dropdown-toggle" data-bs-toggle="dropdown" aria-expanded="false">
              <i className="fa fa-ellipsis-v"/>
            </button>
            <ul className="dropdown-menu dropdown-menu-end">
              <li>
                <a className="dropdown-item" title="Convert to JPEG and Download" href={convertLink}><i className="fa fa-flask"/> Download as JPEG</a>
              </li>
              <Writer>
                <li>
                  <a className="dropdown-item" href="javascript:" onClick={publishSelection}><i className="fa fa-eye"/> Publish</a>
                </li>
                <li>
                  <a className="dropdown-item" href="javascript:" onClick={restrictSelection}><i className="fa fa-eye-slash"/> Unpublish</a>
                </li>
              </Writer>
            </ul>
          </div>
          <button
            type="button"
            title="Close"
            className="btn"
            onClick={onExit}
          >
            <i className="fa fa-times"/>
          </button>
        </div>
      </div>
    </nav>

    <div className={helperClasses.join ' '}>
      {
        selectedTags().map (match) ->
          tag = match.tag

          del = ->
            Store.removeTagFromSelection tag.id

          select = ->
            if showTagLabels
              setShowTagLabels false
            else
              setShowTagLabels true

          tagIconURL = Store.resizedURL 'square', tag.icon_id, tag.icon_code

          <span key={tag.id}>
            {
              img = <img title={tag.alias || tag.label} className="tag-icon" onClick={select} src={tagIconURL}/>
              if showTagLabels
                <div className="selected">
                  {img}
                  <span>
                    {" #{tag.alias || tag.label} (#{match.count}) "}
                    <button className="delete btn btn-sm btn-outline-danger" onClick={del}><i className="fa fa-trash"/></button>
                  </span>
                </div>
              else
                img
            }
          </span>
      }
      {
        tags.map (part) ->
          if part.match?
            tag = part.match
            tagIconURL = Store.resizedURL "square", tag.icon_id, tag.icon_code

            <span key={tag.id}>
              <img title={tag.alias || tag.label} className="tag-icon new" src={tagIconURL}/>
              {
                if part.current
                  " #{tag.alias || tag.label}"
              }
            </span>
          else
            <span key={part.miss}>
              <strong>
                <i className="fa fa-exclamation-circle"/> {part.miss}
              </strong>
            </span>
      }
    </div>
  </div>
