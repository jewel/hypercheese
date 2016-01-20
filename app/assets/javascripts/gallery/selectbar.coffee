@SelectBar = React.createClass
  getInitialState: ->
    caretPosition: 0
    tagging: false
    showTagLabel: null

  startTagging: ->
    @setState
      tagging: true

  stopTagging: ->
    @setState
      tagging: false

  clearSelection: (e) ->
    Store.state.selectMode = false
    Store.clearSelection()

  shareSelection: (e) ->
    Store.shareSelection().then (url) ->
      window.prompt "The items are available at this link:", url

  changeNewTags: (e) ->
    Store.state.pendingTags = TagMatch.matchMany e.target.value, e.target.selectionStart
    Store.state.pendingTagString = e.target.value
    @setState
      caretPosition: e.target.selectionStart
      showTagLabel: null
    Store.forceUpdate()

  moveCaret: (e) ->
    Store.state.pendingTags = TagMatch.matchMany Store.state.pendingTagString, e.target.selectionStart
    @setState
      caretPosition: e.target.selectionStart
      showTagLabel: null

  addNewTags: (e) ->
    e.preventDefault()
    matches = []
    misses = []
    for part in Store.state.pendingTags
      matches.push part.match if part.match?
      misses.push part.miss if part.miss?

    if matches.length > 0
      Store.addTagsToSelection matches

    if misses.length == 0
      Store.state.pendingTagString = ""
      Store.clearSelection()
      @setState
        tagging: false
    else
      Store.state.pendingTagString = misses.join(', ')
      Store.forceUpdate()

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

    downloadLink = "/items/download?ids=#{ids.join ','}"

    tags = Store.state.pendingTags

    classes = ['navbar']
    if @props.fixed
      classes.push 'navbar-fixed-top'
    else
      classes.push 'navbar-static-top'

    <div>
      {
        if @props.fixed
          <nav style={visibility: 'invisible'} className="navbar navbar-static-top"></nav>
      }
      <nav id="select-navbar" className={classes.join ' '}>
        <div className="container-fluid">
          <a className="btn navbar-btn" onClick={@clearSelection}> <i className="fa fa-times fa-fw"/> </a>
          <span className="navbar-text">{" #{Store.state.selectionCount.toLocaleString()} "}</span>
          <form onSubmit={@addNewTags} style={display: 'inline-block', width: if @state.tagging then '200px' else '120px'}>
            <input className="form-control" onFocus={@startTagging} onBlur={@stopTagging} style={display: 'inline-block'} placeholder="Add tags" value={Store.state.pendingTagString} onChange={@changeNewTags} type="text" onClick={@moveCaret} autoFocus={!Store.state.hasTouch} onKeyUp={@moveCaret}/>
          </form>

          <div className="pull-right">
            <a href="javascript:void(0)" className="btn navbar-btn dropdown-toggle pull-right" data-toggle="dropdown">
              <i className="fa fa-ellipsis-v fa-fw"/>
            </a>
            <ul className="dropdown-menu pull-right">
              <li>
                <a title="Rotate Left" href="javascript:void(0)"><i className="fa fa-rotate-right"/> Rotate Left</a>
              </li>
              <li>
                <a title="Rotate Right" href="javascript:void(0)"><i className="fa fa-rotate-left"/> Rotate Right</a>
              </li>
            </ul>
            <a title="Share" className="btn navbar-btn pull-right" href="javascript:void(0)" onClick={@shareSelection}><i className="fa fa-share-alt"/></a>
            <a title="Download" className="btn navbar-btn pull-right" href={downloadLink}><i className="fa fa-download"/></a>
          </div>
          <div>
            {
              @selectedTags().map (match) =>
                tag = match.tag

                del = ->
                  Store.removeTagFromSelection tag.id

                select = =>
                  if @state.showTagLabel == tag.id
                    @setState
                      showTagLabel: null
                  else
                    @setState
                      showTagLabel: tag.id

                tagIconURL = "/data/resized/square/#{tag.icon}.jpg"
                if tag.icon == null
                  tagIconURL = "/images/unknown-icon.png"

                <span key={tag.id}>
                  <img title={tag.label} className="tag-icon" onClick={select} src={tagIconURL}/>
                  {
                    if @state.showTagLabel == tag.id
                      <span>
                        {" #{tag.label} (#{match.count}) "}
                        <a href="javascript:void(0)" className="delete" onClick={del}><i className="fa fa-trash"/></a>
                      </span>
                  }
                </span>
            }
            {
              tags.map (part) ->
                if part.match?
                  tag = part.match
                  tagIconURL = "/data/resized/square/#{tag.icon}.jpg"
                  if tag.icon == null
                    tagIconURL = "/images/unknown-icon.png"

                  <span key={tag.id}>
                    <img title={tag.label} className="tag-icon" src={tagIconURL}/>
                    {
                      if part.current
                        " #{tag.label}"
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
      </nav>
    </div>

