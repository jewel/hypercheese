@NavBar = React.createClass
  selectedTags: ->
    index = {}
    tags = []
    Bridge.selection.forEach (item) ->
      item.get('tags').forEach (tag) ->
        obj = index[tag.id]
        if !obj
          obj = index[tag.id] =
            tag: tag
            count: 0
          tags.push obj
        obj.count++

    tags

  selectedMenu: ->
    <div>
      <ul className="nav navbar-nav">
        <li>
          <p className="navbar-text"> Selected: {Bridge.selection.get('length')}</p>
        </li>

        <li>
          <form className="navbar-form navbar-left">
            <a className="btn btn-default">Clear</a>
          </form>
        </li>

        {
          @selectedTags().map (match) ->
            <p className="navbar-text">
              {match.tag.get('label')}
              ({match.count})
              <a href="javascript:void(0)">&times;</a>
            </p>
        }
      </ul>

      <form className="navbar-form navbar-left">
        {
          if Bridge.selection.get('length') == 1
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
      <form className="navbar-form navbar-left" role="Search">
        <div className="form-group">
          <input className="form-control" placeholder="Search" type="text"/>
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
        Count: {@props.results.get('length')}
      </p>
    </div>

  render: ->
    console.log 'rendering navbar'
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
            if Bridge.selection.get('length') > 0
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
