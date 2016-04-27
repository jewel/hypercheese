@TagList = React.createClass
  getInitialState: ->
    filter: ""

  updateFilter: (e) ->
    @setState
      filter: e.target.value

  filterTest: (tag) ->
    for part in @state.filter.split(/\s+/)
      part = part.toLowerCase()
      return false if tag.label.toLowerCase().indexOf(part) == -1

    true

  newTag: ->
    label = window.prompt("Tag name", "Untitled")
    if label != null
      Store.newTag(label, null)


  render: ->
    tags = Store.state.tags
    tags.forEach (tag) ->
      tag.children = []

    roots = []

    tags.forEach (tag) ->
      if tag.parent_id
        parent = Store.state.tagsById[tag.parent_id]
        parent.children.push tag
      else
        roots.push tag

    setCategory = (tag, parent) ->
      tag.category = parent
      tag.children.forEach (child) ->
        setCategory child, parent + "/" + tag.label

    roots.forEach (tag) ->
      setCategory tag, ''

    drawCategory = (tag) =>
      <div>
        <h2>{tag.label}</h2>
        <div className="tag-list">
          {
            ([tag].concat(tag.children)).map (tag) =>
              if @filterTest(tag)
                <div key={tag.id} className="tag">
                  <a href={"#/tags/#{tag.id}/#{encodeURI tag.label}"}>
                    <Tag tag=tag />
                  </a>
                  {" #{tag.label} (#{tag.item_count.toLocaleString()}) "}
                </div>
          }
        </div>
      </div>

    <div className="container-fluid tag-list-page">
      <a className="pull-right btn" href="javascript:void(0)" onClick={Store.navigateBack}><i className="fa fa-times"/></a>
      <h1>Tags</h1>
      <div className="col-md-3 input-group">
        <span className="input-group-addon"><i className="fa fa-search fa-fw"/></span>
        <input type="text" onChange={@updateFilter} className="form-control" placeholder="Filter..." value={@state.filter}/>
      </div>

      <div className="new-tag">
        <a href="javascript:void(0)" onClick={@newTag}>
          <i className="fa fa-plus-circle"/>
        </a>
        <br/>
        <em>
          New Tag
        </em>
      </div>

      {
        roots.map (i) ->
          drawCategory(i)
      }
    </div>
