@SelectBar = createReactClass
  getInitialState: ->
    Store.state.pendingTags = []
    Store.state.pendingTagString = ""

    caretPosition: 0
    showTagLabels: false

  componentDidMount: ->
    Store.state.openStack.push 'select'

  onExit: (e) ->
    Store.state.selectMode = false
    Store.clearSelection()

  shareSelection: (e) ->
    Store.shareSelection().then (url) ->
      window.prompt "The items are available at this link:", url

  publishSelection: (e) ->
    Store.changeSelectionVisibility true

  restrictSelection: (e) ->
    Store.changeSelectionVisibility false

  changeNewTags: (e) ->
    if e.target.value == '.'
      Store.addTagsToSelection Store.state.lastTags
      return

    Store.state.pendingTags = TagMatch.matchMany e.target.value, e.target.selectionStart
    Store.state.pendingTagString = e.target.value
    @setState
      caretPosition: e.target.selectionStart
      showTagLabels: false
    Store.needsRedraw()

  moveCaret: (e) ->
    Store.state.pendingTags = TagMatch.matchMany Store.state.pendingTagString, e.target.selectionStart
    @setState
      caretPosition: e.target.selectionStart
      showTagLabels: false

  addNewTags: (e) ->
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

  selectedTags: ->
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

  render: ->
    ids = []
    for id of Store.state.selection
      ids.push id

    downloadLink = "/api/items/download?ids=#{ids.join ','}"

    convertLink = "/api/items/convert?ids=#{ids.join ','}"

    tags = Store.state.pendingTags

    classes = ['navbar', 'select-navbar']
    if @props.fixed
      classes.push 'navbar-fixed-top'
    else
      classes.push 'navbar-static-top'

    helperClasses = ['tag-helper']
    if @props.fixed
      helperClasses.push 'tag-helper-fixed'

    <div>
      {
        if @props.fixed
          <nav style={visibility: 'invisible'} className="navbar navbar-static-top"></nav>
      }
      <nav className={classes.join ' '}>
        <div className="container-fluid">
          <span className="navbar-text">{" #{Store.state.selectionCount.toLocaleString()} "}</span>
          <Writer>
            <form onSubmit={@addNewTags}>
              <input className="form-control" placeholder="Add tags" value={Store.state.pendingTagString} onChange={@changeNewTags} type="text" onClick={@moveCaret} autoFocus={!Store.state.hasTouch} onKeyUp={@moveCaret}/>
            </form>
          </Writer>

          <div className="pull-right">
            <Writer>
              <a title="Share" className="btn navbar-btn" href="javascript:void(0)" onClick={@shareSelection}><i className="fa fa-share-alt"/></a>
            </Writer>
            <a title="Download Originals" className="btn navbar-btn" href={downloadLink}><i className="fa fa-download"/></a>
            <a href="javascript:void(0)" className="btn navbar-btn dropdown-toggle" data-toggle="dropdown">
              <i className="fa fa-ellipsis-v"/>
            </a>
            <ul className="dropdown-menu">
              <li>
                <a title="Convert to JPEG and Download" href={convertLink}><i className="fa fa-flask"/> Download as JPEG</a>
              </li>
              <Writer>
                <li>
                  <a href="javascript:void(0)" onClick={@publishSelection}><i className="fa fa-eye"/> Publish</a>
                </li>
                <li>
                  <a href="javascript:void(0)" onClick={@restrictSelection}><i className="fa fa-eye-slash"/> Unpublish</a>
                </li>
              </Writer>
            </ul>
            <a title="Close" className="btn navbar-btn" onClick={@onExit}> <i className="fa fa-times fa-fw"/> </a>
          </div>
        </div>
      </nav>

      <div className={helperClasses.join ' '}>
        {
          @selectedTags().map (match) =>
            tag = match.tag

            del = ->
              Store.removeTagFromSelection tag.id

            select = =>
              if @state.showTagLabels
                @setState
                  showTagLabels: false
              else
                @setState
                  showTagLabels: true

            tagIconURL = Store.resizedURL 'square', tag.icon_id, tag.icon_code

            <span key={tag.id}>
              {
                img = <img title={tag.alias || tag.label} className="tag-icon" onClick={select} src={tagIconURL}/>
                if @state.showTagLabels
                  <div className="selected">
                    {img}
                    <span>
                      {" #{tag.alias || tag.label} (#{match.count}) "}
                      <a href="javascript:void(0)" className="delete btn" onClick={del}><i className="fa fa-trash"/></a>
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
