@NavBar = React.createClass
  handleSearch: (e) ->
    e.preventDefault()
    query = e.target.querySelector('[name=cheesequery]').value
    Store.search query

  clearSelection: (e) ->
    Store.clearSelection()

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

  selectedMenu: ->
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
            <p className="navbar-text">
              {match.tag.label}
              ({match.count})
              <a href="javascript:void(0)">&times;</a>
            </p>
        }
      </ul>

      <form className="navbar-form navbar-left">
        {
          if Store.state.selectionCount == 1
            <a className="btn btn-default">Comment</a>
        }
        {' '}
        <a className="btn btn-default" href="/downloadlink_goes_here">Download</a>
        {' '}
        <a className="btn btn-default" href="javascript:void(0)">Share</a>
      </form>

      <form className="navbar-form navbar-left">
        <div className="form-group">
          <input className="form-control" placeholder="Add tags" type="text"/>
        </div>
      </form>

      <ul className="nav navbar-nav">
        {
          # FIXME TagMatches of the current tag text
          [].map (tag) ->
            <li>
              <p className="navbar-text">{tag.label}</p>
            </li>
        }
      </ul>
    </div>

  searchMenu: ->
    <div>
      <ul className="nav navbar-nav">
        <li>
          <a href="#/tags">Tags</a>
        </li>
      </ul>
      <form className="navbar-form navbar-left" role="Search" onSubmit={@handleSearch}>
        <div className="form-group">
          <input className="form-control" placeholder="Search" defaultValue={Store.state.query} name="cheesequery" type="text"/>
        </div>
      </form>
      <ul className="nav navbar-nav">
        {
          # FIXME TagMatches of the current search
          [].map (tag) ->
            <li>
              <p className="navbar-text">{tag.label}</p>
            </li>
        }
      </ul>
      <p className="navbar-text">
        Count: {Store.state.resultCount}
      </p>
    </div>

  render: ->
    <nav className="navbar navbar-default">
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
          <a className="navbar-brand">HyperCheese</a>
        </div>

        <div className="collapse navbar-collapse" id="hypercheese-navbar-collapse-1">
          <ul className="nav navbar-nav"></ul>

          {
            if Store.state.selectionCount > 0
              @selectedMenu()
            else
              @searchMenu()
          }

          <ul className="nav navbar-nav navbar-right">
            <li>
              <a href="http://www.rickety.us/sundry/hypercheese-help/">Help</a>
            </li>
            <li>
              <a href="/users/sign_out" data-method="delete" rel="nofollow">Sign out</a>
            </li>
          </ul>
        </div>
      </div>
    </nav>
