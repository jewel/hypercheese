@TagList = React.createClass
  getInitialState: ->
    filter: ""

  updateFilter: (e) ->
    @setState
      filter: e.target.value

  filterTest: (tag) ->
    for part in @state.filter.split(/\s+/)
      return false if tag.label.toLowerCase().indexOf(part) == -1

    true

  newTag: (label) ->
    Store.newTag(label)

  render: ->
    tags = Store.state.tags
    <div className="container-fluid tag-editor">
      <a className="pull-right" href="javascript:history.back()"><i className="fa fa-times"/></a>
      <h1>HyperCheese Tag Editor</h1>
      <ul>
        <li>Only tags with no images can be deleted.</li>
        <li>
          To change the tag icon, go into the infomation sidebar for the new
          picture and click the link action next to the tag.
        </li>
      </ul>
      <div className="col-xs-3 input-group">
        <span className="input-group-addon"><i className="fa fa-search fa-fw"/></span>
        <input type="text" onChange={@updateFilter} className="form-control" placeholder="Filter..." value={@state.filter}/>
      </div>

      <h2>Person Tags</h2>
      <div className="tag-list">
        <div className="new-tag">
          <a href="javascript:void(0)" onClick={@newTag.bind(@, "Untitled")}>
            <i className="fa fa-plus-circle"/>
          </a>
          <br/>
          <em>
            New Tag
          </em>
        </div>
        {
          tags.map (tag) =>
            if @filterTest(tag)
              <TagEditor key={tag.id} tag={tag}/>
        }
      </div>
      <p>Total: {tags.length}</p>
      <h2>Place Tags</h2>
      <p>Total: 0</p>

      <h2>Thing Tags</h2>
      <p>Total: 0</p>

      <h2>Adjective Tags</h2>
      <p>Total: 0</p>

      <h2>Meta Tags</h2>
      <p>Total: 0</p>

      <h2>Other Tags</h2>
      <p>Total: 0</p>
    </div>
