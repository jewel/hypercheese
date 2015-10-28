@SelectBar = React.createClass
  getInitialState: ->
    newTags: ''

  clearSelection: (e) ->
    Store.clearSelection()

  shareSelection: (e) ->
    Store.shareSelection().then (url) ->
      window.prompt "The items are available at this link:", url

  changeNewTags: (e) ->
    @setState
      newTags: e.target.value

  selectedTags: ->
    index = {}
    tags = []
    for id of Store.state.selection
      item = Store.state.itemsById[id]
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

    matches = TagMatch.matchMany @state.newTags

    <nav id="select-navbar" className="navbar navbar-default">
      <div className="container-fluid">
        <div className="navbar-header">
          <button className="navbar-toggle collapsed" type="button" data-toggle="collapse" data-target="#hypercheese-navbar-collapse-1">
            <span className="sr-only">
              Toggle Navigation
            </span>
            <span className="icon-bar"></span>
            <span className="icon-bar"></span>
            <span className="icon-bar"></span>
          </button>
        </div>

        <div className="collapse navbar-collapse" id="hypercheese-navbar-collapse-1">
          <ul className="nav navbar-nav"></ul>

          <div>
            <ul className="nav navbar-nav">
              <li>
                <p className="navbar-text"> Selected: {Store.state.selectionCount}</p>
              </li>

              <li>
                <form className="navbar-form navbar-left">
                  <a className="btn btn-default" onClick={@clearSelection}>Clear</a>
                </form>
              </li>

              {
                @selectedTags().map (match) ->
                  <p className="navbar-text" key={match.tag.id}>
                    {match.tag.label}
                    {' '}
                    ({match.count})
                    {' '}
                    <a href="javascript:void(0)">&times;</a>
                  </p>
              }
            </ul>

            <form className="navbar-form navbar-left">
              <a className="btn btn-default" href={downloadLink}>Download</a>
              {' '}
              <a className="btn btn-default" href="javascript:void(0)" onClick={@shareSelection}>Share</a>
            </form>

            <form className="navbar-form navbar-left">
              <div className="form-group">
                <input className="form-control" placeholder="Add tags" value={@state.newTags} onChange={@changeNewTags} type="text"/>
              </div>
            </form>

            <ul className="nav navbar-nav">
              {
                matches.map (tag) ->
                  <li key={tag.id}>
                    <p className="navbar-text">{tag.label}</p>
                  </li>
              }
            </ul>
          </div>

          <ul className="nav navbar-nav navbar-right">
            <li>
              <a href="http://www.rickety.us/sundry/hypercheese-help/">Help</a>
            </li>
          </ul>
        </div>
      </div>
    </nav>
