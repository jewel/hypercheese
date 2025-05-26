component 'TagList', ->
  [filter, setFilter] = useState ""

  updateFilter = (e) ->
    setFilter e.target.value

  filterTest = (tag) ->
    for part in filter.split(/\s+/)
      part = part.toLowerCase()
      return false if (tag.alias || tag.label).toLowerCase().indexOf(part) == -1

    true

  newTag = ->
    label = window.prompt("Tag name", "Untitled")
    if label != null
      Store.newTag(label, null)

  tags = Store.state.tags
  tags.forEach (tag) ->
    tag.children = []

  tags = tags.filter (tag) ->
    filterTest tag

  roots = []

  tags.forEach (tag) ->
    if tag.parent_id
      parent = Store.state.tagsById[tag.parent_id]
      if filterTest parent
        parent.children.push tag
        return
    roots.push tag

  setCategory = (tag, parent) ->
    if parent == ''
      tag.category = tag.alias || tag.label
    else
      tag.category = parent + "/" + (tag.alias || tag.label)
    tag.children.forEach (child) ->
      setCategory child, tag.category

  roots.forEach (tag) ->
    setCategory tag, ''

  roots.sort (a, b) ->
    if a.children.length > b.children.length
      -1
    else if a.children.length < b.children.length
      1
    else
      0

  drawCategory = (tag) ->
    res = [
      <div key={tag.id}>
        <h2>{tag.category}</h2>
        <div className="tag-list">
          {
            ([tag].concat(tag.children)).map (child) ->
              if child.children.length == 0 || tag == child
                <div key={child.id} className="tag">
                  <TagLink tag={child}/>
                  {" #{(child.alias || child.label)} (#{child.item_count.toLocaleString()}) "}
                </div>
          }
        </div>
      </div>
    ]
    more = tag.children.map (child) ->
      if child.children.length > 0
        drawCategory(child)
    res.concat more

  <div className="container-fluid tag-list-page">
    <button className="pull-right btn" onClick={Store.navigateBack}><i className="fa fa-times"/></button>
    <h1>Tags</h1>
    <div className="col-md-3 input-group">
      <span className="input-group-addon"><i className="fa fa-search fa-fw"/></span>
      <input type="text" onChange={updateFilter} className="form-control" placeholder="Filter..." value={filter}/>
    </div>

    <Writer>
      <div className="new-tag">
        <button onClick={newTag}>
          <i className="fa fa-plus-circle"/>
        </button>
        <br/>
        <em>
          New Tag
        </em>
      </div>
    </Writer>

    {
      roots.map (i) ->
        drawCategory(i)
    }
  </div>
