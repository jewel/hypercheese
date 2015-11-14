@SelectBar = React.createClass
  getInitialState: ->
    newTags: ''
    confirmCreateTags: false

  clearSelection: (e) ->
    Store.clearSelection()

  shareSelection: (e) ->
    Store.shareSelection().then (url) ->
      window.prompt "The items are available at this link:", url

  changeNewTags: (e) ->
    @setState
      newTags: e.target.value
      confirmCreateTags: false

  addNewTags: (e) ->
    e.preventDefault()
    res = TagMatch.matchMany @state.newTags
    matches = []
    misses = []
    for part in res
      matches.push part.match if part.match?
      misses.push part.miss if part.miss?

    if matches.size > 0
      Store.addTagsToSelection res.matches

    if misses.size == 0
      Store.clearSelection()
      @setState
        newTags: ''
    else
      @setState
        newTags: misses.join(', ')
        confirmCreateTags: true

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

    tags = TagMatch.matchMany @state.newTags

    <div>
      <nav style={visibility: 'invisible'} className="navbar navbar-static-top"></nav>
      <nav id="select-navbar" className="navbar navbar-fixed-top">
        <div className="container-fluid">
          <a className="navbar-brand" onClick={@clearSelection}> <i className="fa fa-times"/> </a>
          <a className="navbar-brand">{" #{Store.state.selectionCount} "}</a>

          <div className="pull-right">
            <a title="Download" className="btn navbar-btn" href={downloadLink}><i className="fa fa-download"/></a>
            <a title="Share" className="btn navbar-btn" href="javascript:void(0)" onClick={@shareSelection}><i className="fa fa-share-alt"/></a>
            <a href="javascript:void(0)" className="btn navbar-btn dropdown-toggle" data-toggle="dropdown">
              <i className="fa fa-ellipsis-v fa-fw"/>
            </a>
            <ul className="dropdown-menu">
              <li><a href="#/tags" className="dropdown">Tags</a></li>
              <li>
                <a title="Rotate Left" className="dropdown" href="javascript:void(0)"><i className="fa fa-rotate-right"/> Rotate Left</a>
              </li>
              <li>
                <a title="Rotate Right" className="dropdown" href="javascript:void(0)"><i className="fa fa-rotate-left"/> Rotate Right</a>
              </li>
            </ul>
          </div>
        </div>
      </nav>
    </div>

  bender: ->
    <div>
      {
        @selectedTags().map (match) =>
          del = ->
            Store.removeTagFromSelection match.tag.id

          tagIconURL = "/data/resized/square/#{match.tag.icon}.jpg"

          <p className="navbar-text" key={match.tag.id}>
            <img className="tag-icon" src={tagIconURL}/>
            {' '}
            {match.tag.label}
            {' '}
            ({match.count})
            {' '}
            <a href="javascript:void(0)" className="delete" onClick={del}><i className="fa fa-trash"/></a>
          </p>
      }
      <div className="form-group">
        <input className="form-control" autoFocus placeholder="Add tags" value={@state.newTags} onChange={@changeNewTags} type="text"/>
      </div>

      <ul className="nav navbar-nav">
        {
          if @state.confirmCreateTags
            <li key="confirm">
              <p className="navbar-text">
                <em>Press ENTER again to create these tags:</em>
              </p>
            </li>
        }
        {
          tags.map (part) ->
            if part.match?
              tag = part.match
              tagIconURL = "/data/resized/square/#{tag.icon}.jpg"

              <li key={tag.id}>
                <p className="navbar-text">
                  <img className="tag-icon" src={tagIconURL}/>
                  {' '}
                  {tag.label}
                </p>
              </li>
            else
              <li key={part.miss}>
                <p className="navbar-text">
                  <strong>
                    <i className="fa fa-plus-circle"/> {part.miss}
                  </strong>
                </p>
              </li>
        }
      </ul>
    </div>
